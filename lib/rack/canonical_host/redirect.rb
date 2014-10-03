require 'addressable/uri'

module Rack
  class CanonicalHost
    class Redirect
      HTML_TEMPLATE = <<-HTML.gsub(/^\s+/, '')
        <!DOCTYPE html>
        <html lang="en-US">
          <head><title>301 Moved Permanently</title></head>
          <body>
            <h1>Moved Permanently</h1>
            <p>The document has moved <a href="%s">here</a>.</p>
          </body>
        </html>
      HTML

      def initialize(env, host, options={})
        @env = env
        @host = host
        @force_ssl = options[:force_ssl]
        @if = Array(options[:if])
        @unless = Array(options[:unless])
      end

      def canonical?
        (known? && ssl?) || !if_conditions_match? || unless_conditions_match?
      end

      def response
        headers = { 'Location' => new_url, 'Content-Type' => 'text/html' }
        [301, headers, [HTML_TEMPLATE % new_url]]
      end

    private

      def known?
        @host.nil? || request_uri.host == @host
      end

      def ssl?
        !@force_ssl || request_uri.scheme == "https"
      end

      def if_conditions_match?
        return true unless @if.size > 0
        @if.include?( request_uri.host ) || any_regexp_match?( @if, request_uri.host )
      end
      private :if_conditions_match?

      def unless_conditions_match?
        return false unless @unless.size > 0
        @unless.include?( request_uri.host ) || any_regexp_match?( @unless, request_uri.host )
      end
      private :unless_conditions_match?

      def any_regexp_match?( regexp_array, string )
        regexp_array.any?{ |r| string[r] }
      end
      private :any_regexp_match?

      def new_url
        request_uri.tap { |uri|
          uri.host = @host if @host
          uri.scheme = "https" if @force_ssl
        }.to_s
      end

      def request_uri
        Addressable::URI.parse(Rack::Request.new(@env).url)
      end
    end
  end
end
