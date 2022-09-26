require 'yaml'
require 'mustache'
require 'kramdown'
require 'kramdown-syntax-coderay'
require 'rouge'
require 'date'

class YAMLFrontMatter
  PATTERN = /\A(---\r?\n(.*?)\n?^---\s*$\n?)/m.freeze

  class << self
    def extract(content)
      if content =~ PATTERN
        [YAML.load(Regexp.last_match(2), permitted_classes: [Symbol, Date]), content.sub(Regexp.last_match(1), "")]
      else
        [{}, content]
      end
    end
  end
end

class Upstart < Rouge::RegexLexer
  title "Upstart"
  desc "Upstart"
  tag 'upstart'

  def self.keywords
    %w[exec setuid setgid chdir description start stop]
  end

  start { push :root }

  state :root do
    rule %r/\s+/, Text
    rule %r/[;#].*/, Comment
    rule %r/\b(?:#{Upstart.keywords.join('|')})\b/, Keyword
      rule %r/".*"/, Str
    rule %r/.+/, Text
  end
end

module Builder
  def self.human_date(date)
    date.strftime("%B %d, %Y")
  end

  def self.read_article(filename)
    contents = File.read(filename)
    basename = File.basename(filename).sub(/\..*/, '')

    front_matter, body = YAMLFrontMatter.extract(contents)
    article = front_matter.merge("body" => body)

    article.merge(
      "excerpt" => article["excerpt"]&.gsub(/\s+/, " ")&.strip,
      "basename" => basename,
      "path" => "/articles/#{basename}.html",
      "isJournal" => article["kind"] == "journal",
      "human_created_at" => human_date(article["created_at"]),
    )
  end

  def self.apply_markdown(article)
    md_options =  {
      syntax_highlighter: :rouge,
      syntax_highlighter_opts: {
        default_lang: "terminal?prompt=$ ,# &output=plaintext&output.token=Text&lang=plaintext&lang.token=Generic.Strong",
        line_numbers: :table,
        span: { disable: true },
      },
    }

    parsed = Kramdown::Document.new(article["body"], md_options)

    excerpt = article["excerpt"]
      &.then { |excerpt| Kramdown::Document.new(excerpt, md_options) }
      &.to_html

    article.merge(
      "body" => parsed.to_html,
      "excerpt_html" => excerpt,
      "excerpt" => article["excerpt"]&.gsub(/\s+/, " ")&.strip,
      "toc" => parsed.to_toc.children.each.map { |x| { text: x.value.options[:raw_text], id: x.attr[:id] } },
      "hasTOC" => parsed.to_toc.children.any?,
    )
  end

  def self.render(path, data)
    File.write(
      "build/#{path}",
      if File.exists?("src/templates/#{path}.mustache")
        Mustache.render(File.read("src/templates/#{path}.mustache"), data)
      else
        File.read("src/#{path}")
      end,
    )
  end

  def self.run
    articles =
      Dir['src/{articles,journal}/*.md']
      .map { |filename| apply_markdown(read_article(filename)) }
      .reject { |article| article.fetch('draft', false) }
      .sort_by { |article| article['created_at'] }
      .reverse

    data = {
      articles: articles,
      updated_at: articles.map {|x|x["created_at"]}.max,
      recent_articles: articles.take(3),
    }

    `rm -rf build/`
    `mkdir -p build/articles/`
    `cp src/articles/*.png build/articles/`
    `cp src/articles/*.jpg build/articles/`
    `cp src/articles/*.mp4 build/articles/`
    `cp src/articles/*.webm build/articles/`
    `cp src/site.css build/site.css`
    `cp src/favicon.ico build/favicon.ico`
    `cp -r src/images build/images`
    `bundle exec rougify style github > build/rouge.css`

    render("about.html", data)
    render("articles.html", data)
    render("articles.xml", data)
    render("contact.html", data)
    render("index.html", data)

    articles.each do |article|
      File.write(
        "build#{article["path"]}",
        Mustache.render(File.read('src/templates/article.html.mustache'), article),
      )
    end
  end
end

if __FILE__ == $0
  Builder.run
end
