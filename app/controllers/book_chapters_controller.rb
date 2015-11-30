class BookChaptersController < ApplicationController
  before_action :set_book
  before_action :authenticate_user!, only:[ :create, :new]
  before_action :set_book_chapter, only: [:show, :edit, :update, :destroy, :big_show]
  before_action :get_volume_for_select, only: [:update]
  def index
    @books = Book.all
    @books = filter_page(@books)
  end

  def new
    @book_chapter = @book.book_chapters.new
    get_volume_for_select
  end

  def show
    sql = "update books set click_count = click_count + 1 where id = #{@book.id}"
    _sql = ActiveRecord::Base.connection()
    _sql.update(sql)
  end

  def big_show
    @prev_book_chapter = @book_chapter
    @arr = [@book_chapter]
    (1..19).each {
      @book_chapter = @book_chapter.next_chapter
      @arr << @book_chapter
    }
  end

  def edit
    get_volume_for_select
  end

  def create
    prev_book_chapter = BookChapter.find_by(id: params_book_chapter[:prev_chapter_id])
    next_chapter = get_next_chapter_id(prev_book_chapter)
    @book_chapter = @book.book_chapters.new(params_book_chapter.merge(
      next_chapter_id: next_chapter.try(:id)
    ))
    if @book_chapter.save
      update_prev_chapter_next_chapter prev_book_chapter
      update_next_chapter next_chapter
      book_words_count_update

      flash[:success] = '创建成功'
      redirect_to book_path(@book)
    else
      get_volume_for_select
      flash[:danger] = @book_chapter.errors.messages.map{|k,v| v.join("")}.join(", ")
      render 'new'
    end
  end

  def update
    prev_words = @book_chapter.word_count
    if @book_chapter.update(params_book_chapter)
      @book.words = @book.words.to_i - prev_words + @book_chapter.word_count
      @book.save
      flash[:success] = '更新成功'
      redirect_to book_book_chapter_path(@book, @book_chapter)
    else
      flash[:danger] = '更新失败'
      render 'edit'
    end
  end

  def destroy
    _prev_chapter = @book_chapter.prev_chapter
    _next_chapter = @book_chapter.next_chapter
    if @book_chapter.destroy
      _prev_chapter.update(next_chapter_id: _next_chapter.try(:id)) if _prev_chapter.present?
      _next_chapter.update(prev_chapter_id: _prev_chapter.try(:id)) if _next_chapter.present?

      flash[:success] = '删除成功'
      redirect_to book_path(@book)
    else
      flash[:danger] = '删除失败'
      render 'show'
    end
  end

  def get_chapter
    if params[:book_volume_id].present?
      set_book_volume
      @chapter = @book_volume.book_chapters.order(id: :asc).last
      if @chapter.nil?
        prev_book_volume = @book_volume.prev_volume
        if prev_book_volume.present?
          @chapter = prev_book_volume.book_chapters.last
        else
          @chapter = @book.book_chapters.where(book_volume_id: nil).order(id: :asc).last
        end
      end
    else
      @chapter = @book.book_chapters.where(book_volume_id: nil).order(id: :asc).last
    end

    render json:{
               id: @chapter.try(:id),
               name: @chapter.try(:title).to_s
           }
  end

  # ===============================================================================================================
  private

  def params_book_chapter
    params_encoded params.require(:book_chapter).permit(:title, :content, :word_count, :book_volume_id, :prev_chapter_id)
  end

  def set_book_chapter
    @book_chapter = @book.book_chapters.find(params[:id])
  end

  def set_book_volume
    @book_volume = @book.book_volumes.find(params[:book_volume_id])
  end

  def set_book
    @book = Book.find(params[:book_id])
  end

  def get_volume_for_select
    @book_volumes = @book.book_volumes.order(id: :desc)
    if @book_volumes
      __book_chapters = @book.book_chapters.where("book_volume_id is not null").order(book_volume_id: :asc).order(id: :asc)
      @book_chapter.prev_chapter_id ||= if __book_chapters.present?
         __book_chapters.last.try(:id)
       else
         @book.book_chapters.where(book_volume_id: nil).order(id: :asc).last.try(:id)
       end
    else
      @book_chapter.prev_chapter_id = @book.book_chapters.where(book_volume_id: nil).order(id: :asc).last.try(:id)
    end
    @book_volumes = @book_volumes.map{|k| [k.title, k.id]}
    @book_volumes << ['篇头语',nil]
  end

  def filter_page(relation)
    relation = relation.page(params[:page]).per(params[:per_page])
    relation
  end

  # =创建章节的时候得到下一章的id
  def get_next_chapter_id(prev_book_chapter)
    if prev_book_chapter.present?
      _prev_book_chapter_next = BookChapter.find_by(id: prev_book_chapter.next_chapter_id)
      next_chapter = _prev_book_chapter_next if _prev_book_chapter_next
    elsif book_volume = @book.book_volumes.first
      _book_chapter = book_volume.book_chapters.first
      next_chapter = _book_chapter  if _book_chapter
    end
    next_chapter
  end

  # =更新上一章的下一章为当前章
  def update_prev_chapter_next_chapter prev_book_chapter
    prev_book_chapter.update(next_chapter_id: @book_chapter.id) if prev_book_chapter.present?
  end
  # =更新上一章的下一章的上一章为当前章
  def update_next_chapter _prev_book_chapter_next
    _prev_book_chapter_next.update(prev_chapter_id: @book_chapter.id) if _prev_book_chapter_next.present?
  end
  # =这个看得理解吧
  def book_words_count_update
    @book.words = @book.words.to_i + @book_chapter.word_count
    @book.save
  end
end
