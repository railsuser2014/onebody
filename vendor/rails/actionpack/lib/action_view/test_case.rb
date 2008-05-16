require 'active_support/test_case'

module ActionView
  class NonInferrableHelperError < ActionViewError
    def initialize(name)
      super "Unable to determine the helper to test from #{name}. " +
        "You'll need to specify it using tests YourHelper in your " +
        "test case definition"
    end
  end

  class TestCase < ActiveSupport::TestCase
    class_inheritable_accessor :helper_class
    @@helper_class = nil

    class << self
      def tests(helper_class)
        self.helper_class = helper_class
      end

      def helper_class
        if current_helper_class = read_inheritable_attribute(:helper_class)
          current_helper_class
        else
          self.helper_class = determine_default_helper_class(name)
        end
      end

      def determine_default_helper_class(name)
        name.sub(/Test$/, '').constantize
      rescue NameError
        raise NonInferrableHelperError.new(name)
      end
    end

    ActionView::Base.helper_modules.each do |helper_module|
      include helper_module
    end
    include ActionController::PolymorphicRoutes
    include ActionController::RecordIdentifier

    setup :setup_with_helper_class

    def setup_with_helper_class
      self.class.send(:include, helper_class)
    end

    class TestController < ActionController::Base
      attr_accessor :request, :response

      def initialize
        @request = ActionController::TestRequest.new
        @response = ActionController::TestResponse.new
      end
    end

    private
      def method_missing(selector, *args)
        controller = TestController.new
        return controller.send!(selector, *args) if ActionController::Routing::Routes.named_routes.helpers.include?(selector)
        super
      end
  end
end