#
# Inputs:
#   1st argument: Array in which we search for the element
#   2nd argument: element to be seearched for in the Array
#
# Returned values:
#   -1: element not found
#   otherwise: position of the element in the array (starting at index 0)
#
# Raised errors:
#   Puppet::ParseError: if 1st element is not an Array
#
require 'fileutils'
module Puppet::Parser::Functions
  newfunction(:zookeeper_index, :type => :rvalue) do |args|
    unless args[0].class == Array then
      raise Puppet::ParseError, 'zookeeper_index(): 1st argument must be an array'
    end

    in_array = args[0].collect {|x| x[/^(.*):.*:.*/,1]}
    searched_elt = args[1]
    res = in_array.index searched_elt
    if res.nil?
      -1
    else
      res+1
    end
  end
end
