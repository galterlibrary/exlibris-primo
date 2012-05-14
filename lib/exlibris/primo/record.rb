module Exlibris
  module Primo
    # == Overview
    # Exlibris::Primo::Record is an abstract representation of a Primo record.
    # An instance of Exlibris::Primo::Record can be created by passing
    # in a hash with setup parameters.
    # Valid parameters include:
    #   :base_url, :resolver_base_url, :vid, :institution, :record_id, :record
    # A URL to the native record (dlDisplay.do) and an OpenUrl are generated by default. 
    # If no resolver_base_url is provided, an OpenUrl querystring will be returned.
    # A raw_xml attribute is generated either by the record XML passed in or by fetching it from the record_id.
    # By default the raw_xml is not included in the hash representation, but can be overridden to.
    #
    # == Tips on Extending
    # When extending the class, a few basics guidelines should be observed.
    # 1.  A Exlibris::Primo::Record is initialized from a Hash of parameters.
    #     These params are used to create instance variables of the record attributes.
    #
    # 2.  The following methods are available for overriding:
    #     to_h -    if a sub class creates more instance variables, these should be added to the hash
    #     raw  -    cleans up characters and spaces in raw record and wraps in <record /> tag, implementations may differ
    #
    # == Examples of usage
    #   Record.new({ :base_url => @base_url, :vid => @vid, :record => doc.at("//record") })
    class Record
      require 'json'      

      SEAR_NS = {'sear' => 'http://www.exlibrisgroup.com/xsd/jaguar/search'}
      attr_reader :record_id, :type, :title, :url, :openurl, :creator, :raw_xml
      
      def initialize(parameters={})
          # Get base url of Primo application, required
          base_url = parameters[:base_url]
          raise_required_setup_parameter_error :base_url if base_url.nil?
          # Get base url of link resolver, if blank openurl generates just querystring
          resolver_base_url = parameters[:resolver_base_url]
          # Get vid from parameters, required
          vid = parameters.fetch(:vid, "DEFAULT")
          raise_required_setup_parameter_error :vid if vid.nil?
          # Get institution from parameters, required
          institution = parameters.fetch(:institution, "PRIMO")
          raise_required_setup_parameter_error :institution if institution.nil?
          # Get record: either fetch record from Web Service based on DocId or use passed in record xml, required
          record = (parameters[:record].nil?) ? 
              (parameters[:record_id].nil?) ? 
                  nil : record_from_id(parameters.delete(:record_id), base_url, {:institution => institution, :vid => vid}) : parameters.delete(:record)
          raise_required_setup_parameter_error "record or record_id" if record.nil?
          # Set instance variables for record
          @record_id = record.at("control/recordid",record.namespaces).inner_text unless record.at("control/recordid",record.namespaces).nil?
          @type = record.at("display/type",record.namespaces).inner_text unless record.at("display/type",record.namespaces).nil?
          @title = record.at("display/title",record.namespaces).inner_text unless record.at("display/title",record.namespaces).nil?
          @url = construct_url(base_url, @record_id, institution, vid)
          @openurl = construct_openurl(resolver_base_url, record, @record_id)
          @creator = record.at("display/creator",record.namespaces).inner_text unless record.at("display/creator",record.namespaces).nil?
          @raw_xml = raw(record)
      end

      # Return a hash representation of the primary record attributes
      def to_h
          return {
              "format" => @type.capitalize, 
              "title" => @title, 
              "author" => @creator,
              "url" => @url,
              "openurl" => @openurl
          }
      end
      
      # Return a JSON representation of the PNX record
      def to_json
        Hash.from_xml(raw_xml).to_json
      end
      
      # Method for cleaning up raw xml from record
      def raw(record)
          raw = "<record>"
          # Hack to strip out spacing in record
          record.children.each{|child| raw << child.to_xml.gsub(/\n\s*/, "").gsub(/\s$/, "")}
          raw << "</record>"
          return raw
      end

      private
      # Method for consturcting openurl from record
      def construct_openurl(resolver_base_url, record, record_id)
          raise_required_setup_parameter_error :record if record.nil?
          raise_required_setup_parameter_error :record_id if record_id.nil?
          openurl = (resolver_base_url.nil?) ? "?" : "#{resolver_base_url}?"
          record.search("addata/*",record.namespaces).each do |addata|
            openurl << "rft.#{addata.name}=#{addata.inner_text}&" unless (addata.inner_text.nil? or addata.inner_text.strip.empty?)
          end
          openurl << "rft.primo=#{record_id}"
          return openurl
      end
    
      # Method for constructing deep link url from record
      def construct_url(base_url, record_id, institution, vid)
          raise_required_setup_parameter_error :base_url if base_url.nil?
          raise_required_setup_parameter_error :record_id if record_id.nil?
          raise_required_setup_parameter_error :institution if institution.nil?
          raise_required_setup_parameter_error :vid if vid.nil?
          url = "#{base_url}/primo_library/libweb/action/dlDisplay.do?dym=false&onCampus=false&docId=#{record_id}&institution=#{institution}&vid=#{vid}"
          return url
      end

      # Fetch record from Primo Web Service
      def record_from_id(record_id, base_url, options={})
          doc = Exlibris::Primo::WebService::GetRecord.new(record_id, base_url, options).response.at("//sear:DOC", SEAR_NS)
          return doc.at("//xmlns:record",doc.namespaces)
      end

      # Raise error wrapper
      def raise_required_setup_parameter_error(parameter)
          raise ArgumentError.new("Error in #{self.class}. Missing required setup parameter: #{parameter}.")
      end
    end
  end
end