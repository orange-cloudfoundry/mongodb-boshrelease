#!/usr/bin/env bundle exec ruby

require 'bosh/template/renderer'
require 'yaml'
require 'bosh/template/evaluation_context'
require 'erb'


class BoshTemplateRenderer
    def initialize(yaml_spec_file)
        @yaml_spec = File.read(yaml_spec_file)
    end

    def render(template_name)
        spec = YAML.load(@yaml_spec)
        evaluation_context = Bosh::Template::EvaluationContext.new(spec)
        template = ERB.new(File.read(template_name), safe_level = nil, trim_mode = "-")
        template.result(evaluation_context.get_binding)
    end
end

if ARGV.size() == 0 then
	STDERR.puts "Usage: #{File.basename($0)} <bosh_template_erb_file> <bosh_spec_vars_yaml_file>"
	exit 2
end

# First argument is a BOSH ERB template file
bosh_template_file = ARGV[0]
# Second argument is a YAML file
bosh_vars_file = ARGV[1]


renderer = BoshTemplateRenderer.new(bosh_vars_file)
output = renderer.render(bosh_template_file)
puts output
