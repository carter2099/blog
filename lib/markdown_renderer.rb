require "redcarpet"

class MarkdownRenderer
  def self.render_file(path)
    file = File.new(path)
    markdown = Redcarpet::Markdown.new(
      Redcarpet::Render::HTML.new(
        hard_wrap: true,
        filter_html: true
      ),
      fenced_code_blocks: true
    )
    markdown.render(file.read).html_safe
  end
end
