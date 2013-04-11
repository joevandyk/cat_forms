# Warning: This code is atrocious.
#
# ActiveModel is sorta confusing in Rails 3.2.  I think
# it's improved in 4.0?
#

module CatForms
  require 'active_model'
  require 'virtus'
  require 'active_support/core_ext/class/attribute'
  autoload :GzipCookie, 'cat_forms/gzip_cookie'

  # TODO not sure thy this is necessary. tests run, but
  # when this is included by rails, i get already defined
  # errors and super class mismatch errors.
  if !defined?(CatForms::Boolean)
    class Boolean < Virtus::Attribute::Boolean
    end
  end

  module Form

    def self.included base
      base.send :include, ActiveModel::Validations
      base.send :extend,  ActiveModel::Callbacks
      base.send :include, Virtus
      base.send :extend, ClassMethods
      base.send :include, InstanceMethods
      base.instance_eval do
        define_model_callbacks :initialize, :save
        class_attribute :_form_name
      end
      base.send :include, ActiveModel::Validations
    end

    module ClassMethods
      def form_name name
        name = name.to_s

        def name.i18n_key
          self
        end

        def name.human
          self
        end

        def name.singular
          self
        end

        def name.plural
          self
        end

        def name.param_key
          self
        end

        self.class.instance_eval do
          define_method :model_name do
            name
          end
        end

        self._form_name = name
      end

      def model_name
        self._form_name || super
      end

      def form_attribute name, klass, options={}
        # Setup the default values for each attribute.
        options[:default] ||=
          if klass.kind_of?(Array)
            []
          elsif klass == BigDecimal or klass == Boolean or klass == CatForms::Boolean
            ""
          elsif klass.respond_to?(:new)
            klass.new
          else
            ""
          end
        attribute name, klass, options

        # Define an association_attributes= method
        # Rails's fields_for looks for this.
        if klass.kind_of?(Array)
          define_method "#{name}_attributes=" do |hash|
            hash.each do |index, options|
              self.send(name) << klass.first.new(options)
            end
          end
        end
      end

      def custom_attribute attribute_name
        class_eval do
          attr_reader attribute_name
        end
      end

      def validates_associated(*associations)
        validates_each(associations) do |record, associate_name, value|
          (value.respond_to?(:each) ? value : [value]).each do |rec|
            if rec && !rec.valid?
              rec.errors.each do |key, value|
                record.errors.add(key, value)
              end
            end
          end
        end
      end
    end

    module InstanceMethods
      # Need to look into all the below methods, not sure if they are
      # correct.
      def persisted?
        false
      end

      def to_model
        self
      end

      def to_partial_path
        "some_path" # TODO figure out what's needed here for Rails 3.2
      end

      def to_param
        nil
      end

      def to_key
        nil
      end

      def save
        run_callbacks :save do
          if !valid?
            return false
          end
        end
        self
      end

      def initialize options = {}
        run_callbacks :initialize do
          options[:form] ||= {}

          # TODO fix
          # This allows setting of custom things
          options.each do |key, value|
            instance_variable_set "@#{key}", value
          end

          CatForms::GzipCookie.load(storage_options).each do |key, value|
            method = "#{key}="
            if respond_to?(method)
              self.send method, value
            end
          end

          options[:form].each do |name, value|
            value.strip! if value.respond_to?(:strip)
            self.send "#{name}=", value
          end

        end
        super
      end

      def save_to_storage!
        options = storage_options.merge(:attributes => attributes)
        CatForms::GzipCookie.save(options)
      end

      def storage_options
        {
          :cookie_name => @cookie_name,
          :request     => @request,
          :response    => @response
        }
      end
    end
  end
end
