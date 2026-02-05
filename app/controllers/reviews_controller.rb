class ReviewsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]
  before_action :set_review, only: %i[ show edit update destroy ]

  def index
    @review_types = ReviewType.pluck(:name)
    @selected_type = params[:review_type].presence
    @query = params[:q].to_s.strip
    @sort = params[:sort].presence

    @selected_type = nil if @selected_type == "All"
    @reviews = Review.all
    if @selected_type.present?
      @reviews = @reviews.where(review_type: ReviewType.find_by(name: @selected_type))
    end

    if @query.present?
      escaped = Review.sanitize_sql_like(@query)
      @reviews = @reviews.where("title LIKE :q", q: "%#{escaped}%")
    end

    case @sort
    when "rating_desc"
      @reviews = @reviews.order(rating: :desc, created_at: :desc)
    when "rating_asc"
      @reviews = @reviews.order(rating: :asc, created_at: :desc)
    else
      @reviews = @reviews.order(created_at: :desc)
    end
  end

  def show
    @content = MarkdownRenderer.render_file(@review.path)
  end

  def new
    @hide_upload_footer = true
    @review = Review.new
  end

  def create
    @review = Review.new
    review_params = validate_params

    @review.title = review_params[:title]
    @review.review_type = ReviewType.find_by!(name: review_params[:review_type])
    @review.rating = review_params[:rating]
    @review.author = review_params[:author]

    if review_params[:file].present?
      file = review_params[:file]
      @review.path = process_file(file)

      if @review.save
        logger.info("Succesfully saved review: #{@review.inspect}")
        redirect_to @review
      else
        logger.error("Error saving review: #{@review.errors.full_messages}")
        flash.now.alert = "Error saving review: #{@review.errors.full_messages.join(',')}"
        render :new, status: :unprocessable_entity
      end

      if review_params[:images].present?
        process_images(review_params[:images])
      end
    else
      flash.now.alert = "Please provide a file"
      @hide_upload_footer = true
      render :new, status: :bad_request
    end
  rescue ActionController::ParameterMissing => ve
    logger.warn(ve.message)
    render :new, status: :bad_request
  rescue StandardError => e
    logger.error("Error processing review: #{e.message}")
    flash.now.alert = "Error processing review: #{e}"
    @hide_upload_footer = true
    render :new, status: :internal_server_error
  end

  def edit
  end

  def update
    review_params = validate_params

    review_update_args = {
      title: review_params[:title],
      review_type: ReviewType.find_by!(name: review_params[:review_type]),
      rating: review_params[:rating],
      author: review_params[:author]
    }

    if review_params[:file].present?
      file = review_params[:file]
      review_update_args[:path] = process_file(file)
    end

    if review_params[:images].present?
      process_images(review_params[:images])
    end

    if @review.update(review_update_args)
      logger.info("Succesfully updated review: #{@review.inspect}")
      redirect_to @review
    else
      logger.error("Error updating review: #{@review.errors.full_messages}")
      flash.now.alert = "Error updating review: #{@review.errors.full_messages.join(',')}"
      render :edit, status: :unprocessable_entity
    end
  rescue ActionController::ParameterMissing => ve
    logger.warn(ve.message)
    render :new, status: :bad_request
  rescue StandardError => e
    logger.error("Error processing review: #{e.message}")
    flash.now.alert = "Error processing review: #{e}"
    @hide_upload_footer = true
    render :new, status: :internal_server_error
  end

  def destroy
    unless Review.where(path: @review.path).size > 1
      deleted_dir = Rails.root.join("app", "reviews", "deleted")
      FileUtils.mkdir_p(deleted_dir)
      FileUtils.mv(@review.path, deleted_dir.join(File.basename(@review.path)))
    end
    @review.destroy
    redirect_to reviews_path
  end

  private
    def validate_params
      review_params = params.expect(review: {})
      review_params.expect(:title, :review_type, :rating)
      review_params
    end

    def set_review
      @review = Review.find(params[:id])
    end

    def process_file(file)
      logger.info("Received file #{file.original_filename}")
      reviews_dir = Rails.root.join("app", "reviews")
      FileUtils.mkdir_p(reviews_dir)
      new_filename = file.original_filename.gsub(/ /, "-")
      file_path = reviews_dir.join(new_filename)

      content = file.read
      content.gsub!(/!\[\[(.+)\]\]/, '![\1](/assets/\1)')

      File.delete(file_path) if File.exist?(file_path)
      File.binwrite(file_path, content)
      file_path
    end

    def process_images(images)
      images.reject!(&:blank?)
      return unless images.size

      logger.info("Received #{images.size} image(s)")
      images_dir = Rails.root.join("app", "assets", "images")
      FileUtils.mkdir_p(images_dir)
      images.each do |image|
        image_path = images_dir.join(image.original_filename)
        File.delete(image_path) if File.exist?(image_path)
        File.binwrite(image_path, image.read)
      end
      PostsHelper.load_post_images
    rescue StandardError => e
      logger.error("Error processing images: #{e}")
    end
end
