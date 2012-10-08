# All files in the 'lib' directory will be loaded
# before nanoc starts compiling.
include Nanoc::Helpers::LinkTo
include Nanoc::Helpers::Rendering

def xhtml_attrs(lang)
  { 'xml:lang' => lang, 'xmlns' => 'http://www.w3.org/1999/xhtml' }
end

def css_attrs filename, media='screen, projection'
  { :href => filename, :type => 'text/css', :rel => 'stylesheet', :media => media }
end

def javascript_attrs filename
  { :type => 'text/javascript', :src => filename }
end

def external_link_to name, link, options = {}
  rel = ((options[:rel] || '').split(' ') + ['external']).join(' ')

  link_to name, link, options.merge(:rel => rel)
end

def find items, identifier
  items.find { |i| i.identifier == identifier }
end
