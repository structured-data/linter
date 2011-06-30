require 'rubygems'
require 'fileutils'

require 'yard'


YARD::Rake::YardocTask.new do |y|
  y.files = Dir.glob("lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/rdf*/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/json-ld/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/sparql*/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/spira*/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/sxp*/lib/**/*.rb") +
            ["-"] +
            Dir.glob("*-README")
end

desc "Clean documentation"
task :clean_doc do
  FileUtils.rm_rf 'doc'
end

desc "Create README links"
task :readme do
  Dir.glob("*-README").each {|d| FileUtils.rm d}
  Dir.glob('vendor/bundler/**/README').each do |path|
    d = path.split('/')[-2]
    next unless d
    d.sub!(/-([a-z0-9]{12})$/, '')
    d.sub!(/-\d+\.\d+(?:\.\d+)$/, '')
    puts "link #{path} to #{d}-README"
    FileUtils.ln_s path, "#{d}-README" unless File.exist?("#{d}-README")
  end
end