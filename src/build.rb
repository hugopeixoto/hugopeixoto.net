require 'yaml'
require 'mustache'
require 'kramdown'
require 'kramdown-syntax-coderay'

`rm -rf build/`
`mkdir -p build/articles/`
`cp src/about.html build/about.html`
`cp src/articles/*.png build/articles/`
`cp src/contact.html build/contact.html`
`cp src/index.html build/index.html`
`cp src/site.css build/site.css`
`cp src/favicon.ico build/favicon.ico`
`cp -r src/images build/images`

class YAMLFrontMatter
  PATTERN = /\A(---\r?\n(.*?)\n?^---\s*$\n?)/m.freeze

  class << self
    def extract(content)
      if content =~ PATTERN
        [YAML.load(Regexp.last_match(2)), content.sub(Regexp.last_match(1), "")]
      else
        [{}, content]
      end
    end
  end
end

articles = Dir['src/articles/*.{md,yml}'].map do |filename|
  if filename.end_with?(".md")
    front_matter, template = YAMLFrontMatter.extract(File.read(filename))
    [filename, front_matter.merge("body" => template)]
  else
    [filename, YAML.load(File.read(filename))]
  end
end

articles = articles.map do |filename, article|
  [
    filename,
    article.merge(
      "body" => Kramdown::Document.new(
        article["body"],
        syntax_highlighter: :rouge,
        syntax_highlighter_opts: { default_lang: "ruby", line_numbers: :table, span: { disable: true } },
      ).to_html,
     "path" => filename.sub(/.(yml|md)$/, '.html').sub(/^src/, ''),
    ),
  ]
end.sort_by { |a,b| b["created_at"] }.reverse

articles.each do |article, attrs|
  File.write(
    article.sub(/.(yml|md)$/, '.html').sub(/^src/, "build"),
    Mustache.render(
      File.read('src/article.html.mustache'),
      attrs,
    ),
  )
end

File.write(
  "build/articles.html",
  Mustache.render(
    File.read('src/articles.html.mustache'),
    articles: articles.map(&:last),
  ),
)

File.write(
  "build/articles.xml",
  Mustache.render(
    File.read('src/articles.xml.mustache'),
    articles: articles.map(&:last),
  ),
)
