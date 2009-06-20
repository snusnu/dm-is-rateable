require 'pathname'
require Pathname(__FILE__).dirname.expand_path.parent + 'spec_helper'

if HAS_SQLITE3 || HAS_MYSQL || HAS_POSTGRES
  
  module ModelSetup
    
    def unload_rating_infrastructure(remixer_name, user_model_name = nil)
      Object.send :remove_const, "#{remixer_name}Rating" if Object.const_defined? "#{remixer_name}Rating"
      Object.send :remove_const, "#{remixer_name}" if Object.const_defined? "#{remixer_name}"
      Object.send :remove_const, "#{user_model_name}" if Object.const_defined? "#{user_model_name}" if user_model_name
    end
    
  end
  
  describe DataMapper::Is::Rateable do
    
    include ModelSetup
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every rating", :shared => true do

      it "should define a remixed model that can be auto_migrated" do
        # once it's migrated it stays in the database and can be used by the other specs
        Object.const_defined?("TripRating").should be_true
        lambda { TripRating.auto_migrate! }.should_not raise_error
      end
      
      it "should define a 'rateable_model' class_level reader on the remixing model" do
        Trip.respond_to?(:rateable_model).should be_true
        Trip.rateable_model.should == "TripRating"
      end
                  
      it "should define a 'rateable_key' class_level reader on the remixing model" do
        Trip.respond_to?(:rateable_key).should be_true
        Trip.rateable_key.should == :trip_rating
      end

      it "should define a 'rating_togglable?' class method on the remixing model" do
        Trip.respond_to?(:rating_togglable?).should be_true
      end
      
      it "should define a 'anonymous_rating_togglable?' class method on the remixing model" do
        Trip.respond_to?(:anonymous_rating_togglable?).should be_true
      end
      
      it "should define a 'rater_fk' class method on the remixing model" do
        Trip.respond_to?(:rater_fk).should be_true
      end
            
      it "should define a 'rateable_fk' class method on the remixing model" do
        Trip.respond_to?(:rateable_fk).should be_true
      end
       
      it "should use DataMapper foreign_key naming conventions for naming the 'rateable_fk' in the remixing model" do
        Trip.rateable_fk.should == :trip_id
      end
        
      it "should define a 'total_rating' class_level reader on the remixed rateable model" do
        TripRating.total_rating.should == 0
        Trip.total_rating.should == 0
      end
    
      it "should define a 'allowed_ratings' class_level accessor on the remixing model" do
        Trip.allowed_ratings = (0..1)
        Trip.allowed_ratings.should == (0..1)
      end
      
      
      it "should respond_to?(:ratings)" do
        @t1.respond_to?(:ratings).should be_true
      end

      it "should respond_to?(:rating_togglable?)" do
        @t1.respond_to?(:rating_togglable?).should be_true
      end
      
      it "should respond_to?(:anonymous_rating_togglable?)" do
        @t1.respond_to?(:anonymous_rating_togglable?).should be_true
      end
            
      it "should respond_to?(:rating_enabled?)" do
        @t1.respond_to?(:rating_enabled?).should be_true
      end
            
      it "should respond_to?(:rating_disabled?)" do
        @t1.respond_to?(:rating_disabled?).should be_true
      end
            
      it "should respond_to?(:anonymous_rating_enabled?)" do
        @t1.respond_to?(:rating_enabled?).should be_true
      end
                  
      it "should respond_to?(:anonymous_rating_disabled?)" do
        @t1.respond_to?(:rating_enabled?).should be_true
      end
      
      it "should respond_to?(:user_rating)" do
        @t1.respond_to?(:user_rating).should be_true
      end
      
      it "should allow to access the current rating" do
        @t1.rating.should == 0
      end

    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
      
    describe "every rateable where ratings can be toggled", :shared => true do
      
      it "should return true when 'rating_togglable?' class_level reader is called" do
        Trip.rating_togglable?.should be_true
      end
    
      it "should allow to disable and reenable ratings for itself" do
        @t1.disable_rating!
        @t1 = Trip.get(1)
        @t1.rating_enabled?.should be_false
        lambda { @t1.rate(1, @u1) }.should raise_error(DataMapper::Is::Rateable::RatingDisabled)
        @t1.enable_rating!
        @t1 = Trip.get(1)
        @t1.rating_enabled?.should be_true
        lambda { @t1.rate(1, @u1) }.should_not raise_error
      end
    
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    
    describe "every rateable where ratings can't be toggled", :shared => true do
      
      it "should return false when 'rating_togglable?' class_level reader is called" do
        Trip.rating_togglable?.should be_false
      end
    
      it "should raise 'DataMapper::Is::Rateable::TogglableRatingDisabled' when 'disable_rating!' is called" do
        lambda { @t1.disable_rating! }.should raise_error(DataMapper::Is::Rateable::TogglableRatingDisabled)
      end
          
      it "should raise 'DataMapper::Is::Rateable::TogglableRatingDisabled' when 'enable_rating!' is called" do
        lambda { @t1.enable_rating! }.should raise_error(DataMapper::Is::Rateable::TogglableRatingDisabled)
      end
    
    end
    
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
      
    describe "every rateable where anonymous ratings can be toggled", :shared => true do
      
      it "should return true when 'anonymous_rating_togglable?' class_level reader is called" do
        Trip.anonymous_rating_togglable?.should be_true
      end
    
      it "should allow to disable and reenable anonymous ratings for itself" do
        @t1.disable_anonymous_rating!
        @t1 = Trip.get(1)
        @t1.anonymous_rating_enabled?.should be_false
        lambda { @t1.rate(1) }.should raise_error(DataMapper::Is::Rateable::AnonymousRatingDisabled)
        @t1.enable_anonymous_rating!
        @t1 = Trip.get(1)
        @t1.anonymous_rating_enabled?.should be_true
        lambda { @t1.rate(1) }.should_not raise_error
      end
    
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    
    describe "every rateable where anonymous ratings can't be toggled", :shared => true do
      
      it "should return false when 'anonymous_rating_togglable?' class_level reader is called" do
        Trip.anonymous_rating_togglable?.should be_false
      end
    
      it "should raise 'DataMapper::Is::Rateable::TogglableRatingDisabled' when 'disable_anonymous_rating!' is called" do
        lambda { @t1.disable_anonymous_rating! }.should raise_error(DataMapper::Is::Rateable::TogglableAnonymousRatingDisabled)
      end
          
      it "should raise 'DataMapper::Is::Rateable::TogglableRatingDisabled' when 'enable_anonymous_rating!' is called" do
        lambda { @t1.enable_anonymous_rating! }.should raise_error(DataMapper::Is::Rateable::TogglableAnonymousRatingDisabled)
      end
    
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------

    describe "every anonymized timestamped rating", :shared => true do
    
      it "should store timestamps for every anonymous rating" do
        if @t1.anonymous_rating_enabled?
          @t1.rate(5)
          @t1.ratings[0].should respond_to(:created_at)
          @t1.ratings[0].should respond_to(:updated_at)
        end
      end
  
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------

    describe "every anonymized non-timestamped rating", :shared => true do
    
      it "should store timestamps for every anonymous rating" do
        if @t1.anonymous_rating_enabled?
          @t1.rate(5)
          @t1.ratings[0].should_not respond_to(:created_at)
          @t1.ratings[0].should_not respond_to(:updated_at)
        end
      end
  
    end
       
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------

    describe "every personalized timestamped rating", :shared => true do
    
      it "should store timestamps for every personalized rating" do
        if @t1.rating_enabled?
          @t1.rate(5, @u1)
          @t1.ratings[0].should respond_to(:created_at)
          @t1.ratings[0].should respond_to(:updated_at)
        end
      end
  
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------

    describe "every personalized non-timestamped rating", :shared => true do
    
      it "should not store timestamps for every personalized rating" do
        if @t1.rating_enabled?
          @t1.rate(5, @u1)
          @t1.ratings[0].should_not respond_to(:created_at)
          @t1.ratings[0].should_not respond_to(:updated_at)
        end
      end
  
    end
      
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------

    describe "every aliased rating", :shared => true do
    
      it "should set the specified alias on the 'ratings' reader" do
        @t1.respond_to?(:my_trip_ratings).should be_true
      end
  
    end

    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every enabled rating", :shared => true do
      
      it "should have ratings enabled" do
        @t1.rating_enabled?.should be_true
        @t1.rating_disabled?.should be_false
      end
      
    end
            
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every disabled rating", :shared => true do
      
      it "should have ratings disabled" do
        @t1.rating_enabled?.should be_false
        @t1.rating_disabled?.should be_true
      end
      
    end
        
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every enabled anonymized rating", :shared => true do
      
      it "should have anonymized ratings enabled" do
        @t1.anonymous_rating_enabled?.should be_true
        @t1.anonymous_rating_disabled?.should be_false
      end
      
      it "should accept allowed rating values from anonymous users" do
        Trip.allowed_ratings = (0..4)
        lambda { @t1.rate(-1) }.should raise_error(DataMapper::Is::Rateable::ImpossibleRatingValue)
        lambda { @t1.rate( 0) }.should_not raise_error
        lambda { @t1.rate( 4) }.should_not raise_error
        lambda { @t1.rate( 5) }.should raise_error(DataMapper::Is::Rateable::ImpossibleRatingValue)
      end
      
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
     
    describe "every disabled anonymized rating", :shared => true do
      
      it "should have anonymized ratings disabled" do
        @t1.anonymous_rating_disabled?.should be_true
        @t1.anonymous_rating_enabled?.should be_false
      end
      
      it "should not allow any ratings from anonymous users" do
        lambda { @t1.rate(-1) }.should raise_error(DataMapper::Is::Rateable::ImpossibleRatingValue)
        lambda { @t1.rate( 0) }.should raise_error(DataMapper::Is::Rateable::AnonymousRatingDisabled)
        lambda { @t1.rate( 5) }.should raise_error(DataMapper::Is::Rateable::AnonymousRatingDisabled)
        lambda { @t1.rate( 6) }.should raise_error(DataMapper::Is::Rateable::ImpossibleRatingValue)
      end
    
    end
  
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    
    describe "every enabled personalized rating", :shared => true do
      
      it "should accept allowed rating values from existing users" do
        Trip.allowed_ratings = (0..4)
        lambda { @t1.rate(-1, @u1) }.should raise_error(DataMapper::Is::Rateable::ImpossibleRatingValue)
        lambda { @t1.rate( 0, @u1) }.should_not raise_error
        lambda { @t1.rate( 4, @u1) }.should_not raise_error
        lambda { @t1.rate( 5, @u1) }.should raise_error(DataMapper::Is::Rateable::ImpossibleRatingValue)
      end
    
      it "should allow to access any user's current remixed rating model instance" do
        @t1.user_rating(@u1).should be_nil
        @t1.user_rating(@u2).should be_nil
        @t1.rate(5, @u1)
        @t1.user_rating(@u1).should == TripRating.get(1)
        @t1.user_rating(@u2).should be_nil
        @t1.rate(5, @u2)
        @t1.user_rating(@u1).should == TripRating.get(1)
        @t1.user_rating(@u2).should == TripRating.get(2)
      end
    
      it "should store exactly one rating at any time for any given user" do
        @t1.rate(3, @u1)
        @t1.rate(5, @u1)
        TripRating.count.should == 1
        @t1.rate(3, @u2)
        @t1.rate(5, @u2)
        TripRating.count.should == 2
      end
    
      it "should allow any user to rate multiple times without compromising the total_rating" do
        @t1.rate(5, @u1)
        @t2.rate(3, @u2)
        @t1.rating.should == 5
        @t2.rating.should == 3
        TripRating.total_rating.should == 4
        Trip.total_rating.should == 4
        @t1.rate(3, @u1)
        @t2.rate(1, @u2)
        @t1.rating.should == 3
        @t2.rating.should == 1
        TripRating.total_rating.should == 2
        Trip.total_rating.should == 2
      end
    
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "every disabled personalized rating", :shared => true do
    
      it "should not allow any ratings from any existing user" do
        lambda { @t1.rate(-1, @u1) }.should raise_error(DataMapper::Is::Rateable::RatingDisabled)
        lambda { @t1.rate( 0, @u1) }.should raise_error(DataMapper::Is::Rateable::RatingDisabled)
        lambda { @t1.rate( 5, @u1) }.should raise_error(DataMapper::Is::Rateable::RatingDisabled)
        lambda { @t1.rate( 6, @u1) }.should raise_error(DataMapper::Is::Rateable::RatingDisabled)
      end
    
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "allowed_ratings have not been changed", :shared => true do
    
      it "should allow ratings between (0..5)" do
        Trip.allowed_ratings.should == (0..5)
      end
  
    end
        
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
  
    describe "rater association has not been changed", :shared => true do
    
      it "should return the name of the rater association" do
        @t1.rater.should == :user
      end
  
    end
    
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    
    
    describe "Trip.is(:rateable, :rater => :user)" do
    
      before do
      
        unload_rating_infrastructure "Trip", "User"
        
        class User
          include DataMapper::Resource
          property :id, Serial
        end
      
        class Trip
          
          include DataMapper::Resource
          
          property :id, Serial
        
          is :rateable, :rater => :user
          
        end
        
        User.auto_migrate!
        Trip.auto_migrate!
        TripRating.auto_migrate!

        @u1 = User.create(:id => 1)
        @u2 = User.create(:id => 2)
        @t1 = Trip.create(:id => 1)
        @t2 = Trip.create(:id => 2)
      
      end
    
      it_should_behave_like "every rating"
      it_should_behave_like "every enabled rating"
      it_should_behave_like "every disabled anonymized rating"
      it_should_behave_like "every enabled personalized rating"
      it_should_behave_like "every personalized timestamped rating"
      it_should_behave_like "every anonymized timestamped rating"
      it_should_behave_like "every rateable where ratings can't be toggled"
      it_should_behave_like "every rateable where anonymous ratings can't be toggled"
      it_should_behave_like "allowed_ratings have not been changed"
      it_should_behave_like "rater association has not been changed"
    
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    
    describe "Trip.is(:rateable, :rater => :user) with togglable anonymity/rateability" do
    
      before do
      
        unload_rating_infrastructure "Trip", "User"
        
        class User
          include DataMapper::Resource
          property :id, Serial
        end
      
        class Trip
          include DataMapper::Resource
          property :id, Serial
          
          property :rating_enabled,           Boolean, :nullable => false, :default => true
          property :anonymous_rating_enabled, Boolean, :nullable => false, :default => true
        
          # will define TripRating
          is :rateable, :rater => :user
        end
        
        User.auto_migrate!
        Trip.auto_migrate!
        TripRating.auto_migrate!
    
        @u1 = User.create(:id => 1)
        @u2 = User.create(:id => 2)
        @t1 = Trip.create(:id => 1)
        @t2 = Trip.create(:id => 2)
      
      end
    
      it_should_behave_like "every rating"
      it_should_behave_like "every enabled rating"
      it_should_behave_like "every enabled anonymized rating"
      it_should_behave_like "every enabled personalized rating"
      it_should_behave_like "every personalized timestamped rating"
      it_should_behave_like "every anonymized timestamped rating"
      it_should_behave_like "allowed_ratings have not been changed"
      it_should_behave_like "rater association has not been changed"
      it_should_behave_like "every rateable where ratings can be toggled"
      it_should_behave_like "every rateable where anonymous ratings can be toggled"
    
    end

    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
        
    describe "Trip.is(:rateable, :rater => :user, :as => :my_trip_ratings) without additional properties" do
    
      before do
      
        unload_rating_infrastructure "Trip", "User"
        
        class User
          include DataMapper::Resource
          property :id, Serial
        end
      
        class Trip
          include DataMapper::Resource
          property :id, Serial
        
          # will define TripRating
          is :rateable, :rater => :user, :as => :my_trip_ratings
        end
        
        User.auto_migrate!
        Trip.auto_migrate!
        TripRating.auto_migrate!
    
        @u1 = User.create(:id => 1)
        @u2 = User.create(:id => 2)
        @t1 = Trip.create(:id => 1)
        @t2 = Trip.create(:id => 2)
      
      end
    
      it_should_behave_like "every rating"
      it_should_behave_like "every enabled rating"
      it_should_behave_like "every disabled anonymized rating"
      it_should_behave_like "every enabled personalized rating"
      it_should_behave_like "every personalized timestamped rating"
      it_should_behave_like "every anonymized timestamped rating"
      it_should_behave_like "every rateable where ratings can't be toggled"
      it_should_behave_like "every rateable where anonymous ratings can't be toggled"
      it_should_behave_like "allowed_ratings have not been changed"
      it_should_behave_like "rater association has not been changed"
      it_should_behave_like "every aliased rating"
    
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    
    describe "Trip.is(:rateable, :rater => :user, :as => :my_trip_ratings) with togglable anonymity/rateability" do
    
      before do
      
        unload_rating_infrastructure "Trip", "User"
        
        class User
          include DataMapper::Resource
          property :id, Serial
        end
      
        class Trip
          include DataMapper::Resource
          property :id, Serial
          
          property :rating_enabled,           Boolean, :nullable => false, :default => true
          property :anonymous_rating_enabled, Boolean, :nullable => false, :default => true
        
          # will define TripRating
          is :rateable, :rater => :user, :as => :my_trip_ratings
        end
        
        User.auto_migrate!
        Trip.auto_migrate!
        TripRating.auto_migrate!
    
        @u1 = User.create(:id => 1)
        @u2 = User.create(:id => 2)
        @t1 = Trip.create(:id => 1)
        @t2 = Trip.create(:id => 2)
      
      end
    
      it_should_behave_like "every rating"
      it_should_behave_like "every enabled rating"
      it_should_behave_like "every enabled anonymized rating"
      it_should_behave_like "every enabled personalized rating"
      it_should_behave_like "every personalized timestamped rating"
      it_should_behave_like "every anonymized timestamped rating"
      it_should_behave_like "allowed_ratings have not been changed"
      it_should_behave_like "rater association has not been changed"
      it_should_behave_like "every rateable where ratings can be toggled"
      it_should_behave_like "every rateable where anonymous ratings can be toggled"
      it_should_behave_like "every aliased rating"
    
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
        
    describe "Trip.is(:rateable, :rater => :user, :timestamps => false) without additional properties" do
    
      before do
      
        unload_rating_infrastructure "Trip", "User"
        
        class User
          include DataMapper::Resource
          property :id, Serial
        end
      
        class Trip
          include DataMapper::Resource
          property :id, Serial
        
          # will define TripRating
          is :rateable, :rater => :user, :timestamps => false
        end
        
        User.auto_migrate!
        Trip.auto_migrate!
        TripRating.auto_migrate!
    
        @u1 = User.create(:id => 1)
        @u2 = User.create(:id => 2)
        @t1 = Trip.create(:id => 1)
        @t2 = Trip.create(:id => 2)
      
      end
    
      it_should_behave_like "every rating"
      it_should_behave_like "every enabled rating"
      it_should_behave_like "every disabled anonymized rating"
      it_should_behave_like "every enabled personalized rating"
      it_should_behave_like "every personalized non-timestamped rating"
      it_should_behave_like "every anonymized non-timestamped rating"
      it_should_behave_like "every rateable where ratings can't be toggled"
      it_should_behave_like "every rateable where anonymous ratings can't be toggled"
      it_should_behave_like "allowed_ratings have not been changed"
      it_should_behave_like "rater association has not been changed"
    
    end
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
    
    describe "Trip.is(:rateable, :rater => :user, :timestamps => false) with togglable anonymity/rateability" do
    
      before do
      
        unload_rating_infrastructure "Trip", "User"
        
        class User
          include DataMapper::Resource
          property :id, Serial
        end
      
        class Trip
          include DataMapper::Resource
          property :id, Serial
          
          property :rating_enabled,           Boolean, :nullable => false, :default => true
          property :anonymous_rating_enabled, Boolean, :nullable => false, :default => true
        
          # will define TripRating
          is :rateable, :rater => :user, :timestamps => false
        end
        
        User.auto_migrate!
        Trip.auto_migrate!
        TripRating.auto_migrate!
    
        @u1 = User.create(:id => 1)
        @u2 = User.create(:id => 2)
        @t1 = Trip.create(:id => 1)
        @t2 = Trip.create(:id => 2)
      
      end
    
      it_should_behave_like "every rating"
      it_should_behave_like "every enabled rating"
      it_should_behave_like "every enabled anonymized rating"
      it_should_behave_like "every enabled personalized rating"
      it_should_behave_like "every personalized non-timestamped rating"
      it_should_behave_like "every anonymized non-timestamped rating"
      it_should_behave_like "allowed_ratings have not been changed"
      it_should_behave_like "rater association has not been changed"
      it_should_behave_like "every rateable where ratings can be toggled"
      it_should_behave_like "every rateable where anonymous ratings can be toggled"
    
    end
    
    
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------
        
    describe "Trip.is(:rateable, :rater => :account) without additional properties" do
    
      before do
      
        unload_rating_infrastructure "Trip", "User"
        
        class Account
          include DataMapper::Resource
          property :id, Serial
        end
      
        class Trip
          include DataMapper::Resource
          property :id, Serial
        
          # will define TripRating
          is :rateable, :rater => :account
        end
        
        Account.auto_migrate!
        Trip.auto_migrate!
        TripRating.auto_migrate!
    
        @u1 = Account.create(:id => 1)
        @u2 = Account.create(:id => 2)
        @t1 = Trip.create(:id => 1)
        @t2 = Trip.create(:id => 2)
      
      end
    
      it_should_behave_like "every rating"
      it_should_behave_like "every enabled rating"
      it_should_behave_like "every disabled anonymized rating"
      it_should_behave_like "every enabled personalized rating"
      it_should_behave_like "every personalized timestamped rating"
      it_should_behave_like "every anonymized timestamped rating"
      it_should_behave_like "every rateable where ratings can't be toggled"
      it_should_behave_like "every rateable where anonymous ratings can't be toggled"
      it_should_behave_like "allowed_ratings have not been changed"
    
      it "should return the name of the rater association" do
        @t1.rater.should == :account
      end
    
    end
  
    # --------------------------------------------------------------------------------------------------
    # --------------------------------------------------------------------------------------------------

    describe "Trip.is(:rateable) without additional properties" do

      before do

        unload_rating_infrastructure "Trip"

        class Account
          include DataMapper::Resource
          property :id, Serial
        end

        class Trip
          include DataMapper::Resource
          property :id, Serial

          # will define TripRating
          is :rateable
        end

        Account.auto_migrate!
        Trip.auto_migrate!
        TripRating.auto_migrate!

        @t1 = Trip.create(:id => 1)
        @t2 = Trip.create(:id => 2)

      end

      it_should_behave_like "every rating"
      it_should_behave_like "every enabled rating"
      it_should_behave_like "every rateable where ratings can't be toggled"
      it_should_behave_like "every rateable where anonymous ratings can't be toggled"
      it_should_behave_like "allowed_ratings have not been changed"

    end

  end

end
