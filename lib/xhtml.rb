
module XhtmlHelper

	def stylesheet_tag name, options = {}
		newoptions = {
			:href => name + '.css',
			:type => 'text/css',
			:rel => 'stylesheet',
			:media => options[:media] || 'screen, projection'
		}
		'<link%s />' % tag_options(options.merge(newoptions))
	end

  def javascript_tag filename
    "<script src='%s.js' type='text/javascript'></script>" % filename
  end

 	def external_link_to name, link, options = {}
		newoptions = { :class => ((options[:class]||'') + ' external').strip }
 		link_to name, link, :attrs => options.merge(newoptions)
 	end

  def xhtml_attrs(lang)
    { 'xml:lang' => lang, 'xmlns' => 'http://www.w3.org/1999/xhtml' }
  end

end

Webby::Helpers.register XhtmlHelper
