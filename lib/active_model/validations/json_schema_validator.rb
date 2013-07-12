require 'active_model'
require 'json-schema'

module ActiveModel
  module Validations
    class JsonSchemaValidator < EachValidator # :nodoc:
    
      def validate_each(record, attribute, value)
        begin
          return unless json_schema = record.json_schema
          ::JSON::Validator.validate!(json_schema, record.as_json, :validate_schema => true)
        rescue ::JSON::Schema::ValidationError
          record.errors.add(attribute, "not honored. #{$!.message}")
        end
      end
    end # JsonSchemaValidator

    module HelperMethods
      # Validates that the record respects the provided json_schema
      def validates_json_schema
        validates_with(JsonSchemaValidator, {
          :attributes => [:json_schema]
        })
      end
    end
  end
end
