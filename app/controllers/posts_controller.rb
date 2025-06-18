class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  def index
  end

  def show
    @name = params[:name]
    @title = @name
    filename = "#{@name}.md"
  end

  def new
  end

  def create
    flash[:notice] = nil
    flash[:alert] = nil
    if params[:markdown_file].present?
      file = params[:markdown_file]
      logger.info "Received file #{file.original_filename}"

      posts_dir = Rails.root.join("app", "posts")
      FileUtils.mkdir_p(posts_dir)

      new_filename = file.original_filename.gsub(/ /, "-")
      file_path = posts_dir.join(new_filename)
      File.write(file_path, file.read)

      flash[:notice] = "#{file.original_filename} uploaded successfully"
      redirect_to "/posts/#{new_filename}"
    else
      flash[:alert] = "Please select a file"
      render :new, status: :bad_request
    end

  rescue StandardError => e
    flash[:alert] = "Error uploading file: #{e}"
    render :new, status: :internal_server_error
  end
end
