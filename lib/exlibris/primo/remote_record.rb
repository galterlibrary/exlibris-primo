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
    class RemoteRecord < Record
    end
  end
end