class SubscriberMailer < ApplicationMailer
  def confirmation
    @subscriber = params[:subscriber]
    mail(to: @subscriber.email, subject: "Confirm your subscription to blog.carter2099.com")
  end

  def new_post
    @subscriber = params[:subscriber]
    @post = params[:post]
    @content = MarkdownRenderer.render_file(@post.path)
    mail(to: @subscriber.email, subject: "New post: #{@post.title}")
  end

  def new_review
    @subscriber = params[:subscriber]
    @review = params[:review]
    @content = @review.path.present? ? MarkdownRenderer.render_file(@review.path) : nil
    mail(to: @subscriber.email, subject: "New review: #{@review.title}")
  end
end
