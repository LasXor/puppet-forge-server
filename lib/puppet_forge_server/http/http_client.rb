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

require 'open-uri'
require 'open_uri_redirections'
require 'timeout'
require 'net/http'
require 'net/http/post/multipart'


module PuppetForgeServer::Http
  class HttpClient
    include PuppetForgeServer::Utils::CacheProvider
    include PuppetForgeServer::Utils::FilteringInspector

    def initialize(cache = nil)
      @cache = cache || cache_instance
      @cache.extend(PuppetForgeServer::Utils::FilteringInspector)
      @log = PuppetForgeServer::Logger.get
      @uri_options = {
        'User-Agent' => "Puppet-Forge-Server/#{PuppetForgeServer::VERSION}",
        :allow_redirections => :safe,
      }
      # OpenURI does not work with  http_proxy=http://username:password@proxyserver:port/
      # so split the proxy_url and feed it basic authentication.
      if ENV.has_key?('http_proxy')
        proxy = URI.parse(ENV['http_proxy'])
        if proxy.userinfo != nil
          @uri_options[:proxy_http_basic_authentication] = [
            "#{proxy.scheme}://#{proxy.host}:#{proxy.port}",
            proxy.userinfo.split(':')[0],
            proxy.userinfo.split(':')[1]
          ]
        end
      end

    end

    def post_file(url, file_hash, options = {})
      options = { :http => {}, :headers => {}}.merge(options)

      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      options[:http].each {|k,v| http.call(k, v) }

      req = Net::HTTP::Post::Multipart.new uri.path, "file" => UploadIO.new(File.open(file_hash[:tempfile]), file_hash[:type], file_hash[:filename])
      options[:headers].each {|k,v| req[k] = v }

      http.request(req)
    end

    def get(url)
      fetch(url).read
    end

    def download(url)
      fetch(url)
    end

    def inspect
      cache_inspected = @cache.inspect_without [:@data]
      cache_inspected.gsub!(/>$/, ", @size=#{@cache.count}>")
      inspected = inspect_without [:@cache]
      inspected.gsub(/>$/, ", @cache=#{cache_inspected}>")
    end

    private

    def fetch(url)
      hit_or_miss = @cache.key?(url) ? 'HIT' : 'MISS'
      @log.info "Cache in RAM memory size: #{@cache.count}, #{hit_or_miss} for url: #{url}"
      contents = if @cache.key?(url)
                   @cache[url]
                 else
                   @cache[url] = open_url(url)
                 end
      @log.debug "Data for url: #{url} fetched, #{contents.size} bytes"
      StringIO.new(contents)
    end

    def open_url(url)
      uri = URI.parse(url)
      return Net::HTTP.get(uri) if @uri_options[:proxy_http_basic_authentication].nil?

      Net::HTTP.new(uri,
                    p_user: @uri_options[:proxy_http_basic_authentication][1],
                    p_pass: @uri_options[:proxy_http_basic_authentication][2]).start do |http|
        request = Net::HTTP::Get.new uri.request_uri
        response = http.request request
        puts response
        puts response.body
      end
    end
  end
end
