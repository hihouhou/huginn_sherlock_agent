require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::SherlockAgent do
  before(:each) do
    @valid_options = Agents::SherlockAgent.new.default_options
    @checker = Agents::SherlockAgent.new(:name => "SherlockAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
