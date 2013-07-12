require 'test/unit'
require File.expand_path('../../lib/active_model/json/schema.rb', __FILE__)

class ActiveModelJsonSchemaTest < Test::Unit::TestCase
  
  class TestModelSuperClass
    include ActiveModel::Model
    include ActiveModel::JSON::Schema
    
    key :required, String
    key :optional, String, {'optional' => true}
    key :time, Time, {'optional' => true}
  end
  
  class TestModelSubClass < TestModelSuperClass
    key :something_else, String
  end
  
  def test_validating_against_schema
    assert_valid TestModelSuperClass.new({'required' => 'defined'})
    assert_valid TestModelSuperClass.new({'required' => 'defined', 'optional' => 'defined'})
    assert_invalid TestModelSuperClass.new({})
    
    assert_valid TestModelSubClass.new({'required' => 'defined', 'something_else' => 'defined'})
    assert_invalid TestModelSubClass.new({'required' => 'defined'})
  end
  
  def test_time_keys
    time = Time.at(0).utc
    instance = TestModelSuperClass.new({'required' => 'defined', 'time' => time})
    assert_valid instance
    assert_equal "{\"required\":\"defined\",\"time\":\"1970-01-01 00:00:00 UTC\"}", instance.to_json
    from_json = TestModelSuperClass.from_json(instance.to_json)
    assert_equal time, from_json.time
    assert_equal instance.as_json, from_json.as_json
  end
  
  def assert_valid(instance)
    assert_equal true, instance.valid?, instance.errors.full_messages
  end
  
  def assert_invalid(instance)
    assert_equal false, instance.valid?
  end

end