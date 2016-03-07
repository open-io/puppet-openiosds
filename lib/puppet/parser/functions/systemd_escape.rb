require 'puppet/util/execution'

module Puppet::Parser::Functions
    newfunction(:systemd_escape, :type => :rvalue, :doc => <<-EOS
Returns a file system path as escaped by systemd.
EOS
    ) do |args|

        if (args.length != 1) then
            raise Puppet::ParseError, ("validate_cmd(): wrong number of arguments (#{args.length}; must be 1)")
        end

        path = args[0]

        cmd = "systemd-escape --path #{path}"
        escaped = Puppet::Util::Execution.execute(cmd)

        return escaped.strip

    end
end
