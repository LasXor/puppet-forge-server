# -*- encoding: utf-8 -*-
#
# Copyright 2014 North Development AB
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'rack/test'
require 'rspec'
require 'rspec/stopwatch'
require 'puppet_forge_server'

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
end
begin
  gem 'simplecov'
  require 'simplecov'
  formatters = []
  formatters << SimpleCov::Formatter::HTMLFormatter

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(*formatters)
  SimpleCov.start do
    add_filter "/spec/"
    add_filter "/.vendor/"
    add_filter "/vendor/"
    add_filter "/gems/"
    refuse_coverage_drop
  end
rescue Gem::LoadError
  # do nothing
end

begin
  gem 'pry'
  require 'pry'
rescue Gem::LoadError
  # do nothing
end

RSpec.configure do |c|
  c.include RSpecMixin
  c.add_formatter(:documentation)
end
