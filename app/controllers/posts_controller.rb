class PostsController < ApplicationController
  allow_unauthenticated_access only: %i[ index show ]

  def index
  end

  def show
  end

  def new
  end

  def create
    if params[:markdown_file].present?
      file = params[:markdown_file]

      posts_dir = Rails.root.join("app", "posts")
      FileUtils.mkdir_p(posts_dir)

      file_path = posts_dir.join(file.original_filename)
      File.write(file_path, file.read)

      flash[:notice] = "#{file.original_filename} uploaded successfully"
    else
      flash[:alert] = "Please select a file"
    end

    redirect_to "posts/show/#{file.original_filename}"
  rescue StandardError => e
    flash[:alert] = "Error uploading file: #{e}"
  end
end
