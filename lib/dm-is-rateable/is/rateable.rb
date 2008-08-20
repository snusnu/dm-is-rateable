module DataMapper
  module Is
    module Rateable
      
      class DmIsRateableException < Exception; end
      class DmIsRateableRuntimeError < RuntimeError; end
      
      class ImpossibleRatingType < DmIsRateableException; end
      class RatingDisabled < DmIsRateableRuntimeError; end
      class TogglableRatingDisabled < DmIsRateableRuntimeError; end
      class ImpossibleRatingValue < DmIsRateableRuntimeError; end
      
      module Rating

        def self.included(base)
          base.extend ClassMethods
        end

        include DataMapper::Resource

        is :remixable

        # properties

        property :id, Integer, :serial => true
  
        module ClassMethods

          # total rating for all rateable instances of this type
          def total_rating
            rating_sum = self.sum(:rating).to_f
            rating_count = self.count.to_f
            rating_count > 0 ? rating_sum / rating_count : 0
          end

        end
      end

      def is_rateable(options = {})
        
        extend  DataMapper::Is::Rateable::ClassMethods
        include DataMapper::Is::Rateable::CommonInstanceMethods
        
        # merge default options
        options = {
          :rating_module => nil, # only enhance if this is nil
          :anonymous => false,
          :rater => { :fk => :user_id, :fk_type => Integer, :fk_nullable => false, :unique => true },
          :allow_deactivation => true,
          :allowed_ratings => (0..5),
          :timestamps => true,
          :as => nil
        }.merge(options)
        
        @rating_module = options[:rating_module] || DataMapper::Is::Rateable::Rating
        class_inheritable_reader :rating_module
                
        @allow_togglable_rating = options[:allow_deactivation]
        class_inheritable_accessor :allow_togglable_rating
        
        
        # use dm-is-remixable for storage and api
        remix n, self.rating_module, :as => options[:as]
        
        @remixed_rating = remixables[Extlib::Inflection.demodulize(rating_module.name).snake_case.to_sym]
        class_inheritable_reader :remixed_rating
        
        self.class_eval(<<-EOS, __FILE__, __LINE__ + 1)
          alias :ratings #{self.remixed_rating[:reader]}
        EOS
        
        class_inheritable_accessor :allowed_ratings
        self.allowed_ratings = options[:allowed_ratings]        
        
        # rating enabled property 
        property :rating_enabled, DataMapper::Types::Boolean, :nullable => false, :default => true
        
        if options[:anonymous]
          include DataMapper::Is::Rateable::AnonymousRatingInstanceMethods
        else
          include DataMapper::Is::Rateable::PersonalizedRatingInstanceMethods
        end
        
        unless options[:rating_module]
          
          # remember this because enhance will class_eval in remixable model scope 
          parent_key = rateable_fk

          enhance :rating do            
            
            unless options[:anonymous]
          
              rater = options[:rater]
              rater_fk          = rater.is_a?(Hash) ? rater[:fk]          : rater.to_s.snake_case.to_sym
              rater_fk_type     = rater.is_a?(Hash) ? rater[:fk_type]     : Integer
              rater_fk_nullable = rater.is_a?(Hash) ? rater[:fk_nullable] : false
              rater_fk_unique   = rater.is_a?(Hash) ? rater[:unique]      : true            
              
              # properties
              property rater_fk, rater_fk_type, :nullable => rater_fk_nullable
              belongs_to rater_fk.to_s.gsub(/_id/, '').to_sym
              
              # validations
              # don't use auto validation triggers because we want to scope the validation
              if rater_fk_unique
                require 'dm-validations' unless Object.full_const_defined?("DataMapper::Validate")
                parent_assocation = parent_key.to_s.gsub(/_id/, '').to_sym
                validates_is_unique rater_fk, :when => :testing_association, :scope => [parent_assocation]
                validates_is_unique rater_fk, :when => :testing_property, :scope => [parent_key]
              end
                         
            end
            
            # determine property type based on supplied values
            rating_type = case options[:allowed_ratings]
              when Range then Integer
              when Enum  then
                require 'dm-types' unless Object.full_const_defined?("DataMapper::Types")
                DataMapper::Types::Enum
              else
                msg = "#{options[:allowed_ratings].class} is no supported RatingType" 
                raise ImpossibleRatingType, msg
              end
            
            property :rating, rating_type, :nullable => false
          
            if options[:timestamps]
              include DataMapper::Timestamp
              property :created_at, DateTime
              property :updated_at, DateTime
            end
            
          end
          
        end
        
      end

      module ClassMethods
        
        def total_rating
          remixables[:rating][:model].total_rating
        end
        
        def rateable_fk
          demodulized_name = Extlib::Inflection.demodulize(self.name)
          Extlib::Inflection.foreign_key(demodulized_name).to_sym
        end

      end
  
      module CommonInstanceMethods
        
        def rating_enabled?
          self.respond_to?(:rating_enabled) && self.rating_enabled
        end
        
        def rating
          scope = { self.class.rateable_fk => self.id }
          model_class =  self.class.remixables[:rating][:model]
          rating_sum = model_class.sum(:rating, scope).to_f
          rating_count = model_class.count(scope).to_f
          rating_count > 0 ? rating_sum / rating_count : 0
        end
        
        def disable_rating
          if self.class.allow_togglable_rating
            if self.rating_enabled?
              self.rating_enabled = false
              self.save
            end
          else
            raise TogglableRatingDisabled, "Ratings cannot be toggled for #{self}"
          end
        end
        
        def enable_rating
          if self.class.allow_togglable_rating
            unless self.rating_enabled?
              self.rating_enabled = true
              self.save
            end
          else
            raise TogglableRatingDisabled, "Ratings cannot be toggled for #{self}"
          end
        end
        
      end
      
      module AnonymousRatingInstanceMethods
        
        def rate(rating)
          if self.rating_enabled?
            if self.class.allowed_ratings.include?(rating)
              self.ratings.create(:rating => rating)
            else
              raise ImpossibleRatingValue, "Rating (#{rating}) must be in #{allowed_ratings.inspect}"
            end
          else
            raise RatingDisabled, "Ratings are not enabled for #{self.class.name}"
          end
        end
        
        def rating_values(conditions = {})
          self.ratings(conditions).map { |r| r.rating }
        end
        
      end
      
      module PersonalizedRatingInstanceMethods
        
        def rate(rating, user)
          if self.rating_enabled?
            if self.class.allowed_ratings.include?(rating)
              if r = self.user_rating(user)
                if rating != r.rating
                  r.rating = rating
                  r.save
                end
              else
                self.ratings.create(:user => user, :rating => rating)
              end
            else
              msg = "Rating (#{rating}) must be in #{allowed_ratings.inspect}"
              raise ImpossibleRatingValue, msg
            end
          else
            msg = "Ratings are not enabled for #{self.class.name}"
            raise RatingDisabled, msg
          end
        end

        def user_rating(user)
          self.ratings(:user_id => user.id).first
        end
                
        def user_rating_value(user)
          (r = user_rating(user)) ? r.rating : nil
        end
        
      end
      
    end
  end
end