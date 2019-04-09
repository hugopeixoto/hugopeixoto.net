require 'yaml'
require 'mustache'
require 'kramdown'
require 'kramdown-syntax-coderay'

`mkdir -p build/articles/`
`cp src/about.html build/about.html`
`cp src/articles/*.png build/articles/`
`cp src/contact.html build/contact.html`
`cp src/index.html build/index.html`
`cp src/site.css build/site.css`
`cp src/favicon.ico build/favicon.ico`
`cp -r src/images build/images`

articles = Dir['src/articles/*.yml'].map do |article|
  [
    article,
    YAML.load(File.read(article)).yield_self do |a|
      a.merge(
        "body" => Kramdown::Document.new(
          a["body"],
          syntax_highlighter: :coderay,
          syntax_highlighter_opts: { default_lang: :ruby, line_numbers: :table },
        ).to_html,
       "path" => article.sub(/.yml$/, '.html').sub(/^src/, ''),
      )
    end,
  ]
end.sort_by { |a,b| b["created_at"] }.reverse

articles.each do |article, attrs|
  File.write(
    article.sub(/.yml$/, '.html').sub(/^src/, "build"),
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
