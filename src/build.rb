require 'yaml'
require 'mustache'
require 'kramdown'
require 'kramdown-syntax-coderay'

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

def human_date(date)
  date.strftime("%B %d, %Y")
end

def read_article(filename)
  contents = File.read(filename)
  basename = File.basename(filename).sub(/\..*/, '')

  article =
    if filename.end_with?(".md")
      front_matter, template = YAMLFrontMatter.extract(contents)
      front_matter.merge("body" => template)
    else
      YAML.load(contents)
    end

  article.merge(
    "basename" => basename,
    "path" => "/articles/#{basename}.html",
    "isJournal" => article["kind"] == "journal",
    "human_created_at" => human_date(article["created_at"])
  )
end

def apply_markdown(article)
  parsed = Kramdown::Document.new(
    article["body"],
    syntax_highlighter: :rouge,
    syntax_highlighter_opts: {
      default_lang: "terminal?prompt=$,#&output=plaintext&output.token=Text&lang=plaintext&lang.token=Generic.Strong",
      line_numbers: :table,
      span: { disable: true },
    },
  )

  excerpt = article["excerpt"] ? Kramdown::Document.new(
    article["excerpt"],
    syntax_highlighter: :rouge,
    syntax_highlighter_opts: {
      default_lang: "terminal?prompt=$,#&output=plaintext%3ftoken=Text&lang=plaintext%3ftoken=Generic.Strong",
      line_numbers: :table,
      span: { disable: true },
    },
  ).to_html : nil

  article.merge(
    "body" => parsed.to_html,
    "excerpt" => excerpt,
    "toc" => parsed.to_toc.children.each.map { |x| { text: x.value.options[:raw_text], id: x.attr[:id] } },
    "hasTOC" => parsed.to_toc.children.any?,
  )
end

`rm -rf build/`
`mkdir -p build/articles/`
`mkdir -p build/journal/`
`cp src/about.html build/about.html`
`cp src/articles/*.png build/articles/`
`cp src/articles/*.webm build/articles/`
`cp src/contact.html build/contact.html`
`cp src/site.css build/site.css`
`cp src/favicon.ico build/favicon.ico`
`cp -r src/images build/images`

articles =
  Dir['src/{articles,journal}/*.{md,yml}']
  .map { |filename| apply_markdown(read_article(filename)) }
  .sort_by { |article| article["created_at"] }
  .reverse

articles.each do |article|
  File.write(
    "build#{article["path"]}",
    Mustache.render(File.read('src/templates/article.html.mustache'), article),
  )
end

File.write(
  "build/articles.html",
  Mustache.render(
    File.read('src/templates/articles.html.mustache'),
    articles: articles,
  ),
)

File.write(
  "build/articles.xml",
  Mustache.render(
    File.read('src/templates/articles.xml.mustache'),
    articles: articles,
    updated_at: articles.map {|x|x["created_at"]}.max,
  ),
)

File.write(
  "build/index.html",
  Mustache.render(
    File.read('src/templates/index.html.mustache'),
    articles: articles.take(3),
  ),
)
