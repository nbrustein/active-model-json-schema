require File.expand_path("../schema/version", __FILE__)
require File.expand_path("../../validations/json_schema_validator", __FILE__)
require 'active_model'
require 'json-schema'

module ActiveModel
  module JSON
    module Schema
      def self.included(target)
        target.send(:extend, ActiveModel::JSON::SchemaClassMethods)
        target.validates_json_schema
      end
    
      def as_json(options = {})
        hash = {}
        json_schema_properties.each do |key, options|
          value = send("#{key}_as_json")
          hash[key] = value unless value.nil? && options['optional']
        end
        hash
      end
      
      # not sure why I have to do this
      def to_json(options = {})
        as_json(options).to_json
      end
    
      def json_schema
        self.class.json_schema
      end
    
      def json_schema_properties
        self.class.json_schema_properties
      end
    end # end Schema
    
    module SchemaClassMethods
      def json_schema
        properties = json_schema_properties
        properties.each do |key, value|
          map = {
            "string" => String,
            "number" => Numeric,
            "integer" => Integer,
            "boolean" => [TrueClass, FalseClass],
            "object" => Hash,
            "array" => Array,
            "null" => NilClass,
            "any" => Object
          }.invert
          if map.key?(value['type'])
            type = map[value['type']]
          elsif value['type'] == Time || value['type'] == "time"
            type = "string"
          elsif value['type'].is_a?(String)
            type = value['type']
          else
            raise RuntimeError.new("Unsupported type: #{value['type'].inspect}")
          end
          
          properties[key] = {'type' => type}
          
        end
        
        {
          "type" => "object",
          "required" => required_keys,
          "optional" => optional_keys,
          "properties" => properties
        }  
      end
      
      def key(name, type, options = {})
        @json_schema_properties ||= {}
        
        options['required']= true unless options['optional']
        
        @json_schema_properties[name.to_s] = {"type" => type}.merge(options)
        
        attr_accessor name.to_sym
      
        define_method("#{name.to_s}_as_json") {
          if type == "time" || type == Time
            value = send(name.to_sym)
            unless value.is_a?(Time) || value.nil?
              raise RuntimeError.new("Expected a time but was a #{value.class}") 
            end
            value.to_s
          else
            send(name.to_sym)
          end
        }

        define_singleton_method("#{name.to_s}_from_json") { |value|
          if type == "time" || type == Time
            Time.parse(value)
          else
            value
          end
        }
      end

      def from_hash(hash)
        deserialized = {}
        hash.each do |key, value|
          meth = "#{key}_from_json".to_sym
          deserialized[key] = send(meth, value)
        end
        new(deserialized)
      end
      
      def from_json(json)
        hash = ActiveSupport::JSON.decode(json)
        from_hash(hash)
      end
      
      def json_schema_properties
        properties = @json_schema_properties.nil? ? {} : @json_schema_properties.clone
        if superclass.respond_to?(:json_schema_properties)
          properties.merge!(superclass.json_schema_properties)  
        end
        properties
      end
      
      def required_keys
        json_schema_properties.map do |key, value|
          key if value['required']
        end.compact
      end
      
      def optional_keys
        json_schema_properties.map do |key, value|
          key if value['optional']
        end.compact
      end
    
    end
  end
  
end