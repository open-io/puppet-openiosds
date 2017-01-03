module Puppet::Parser::Functions
  newfunction(:to_i, :type => :rvalue) do |args|
    args[0].to_i
  end
end
