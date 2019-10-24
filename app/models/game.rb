class Game < ActiveRecord::Base
  PRIZES = [
    100, 200, 300, 500, 1000,
    2000, 4000, 8000, 16000, 32000,
    64000, 125000, 250000, 500000, 1000000
  ].freeze

  FIREPROOF_LEVELS = [4, 9, 14].freeze

  TIME_LIMIT = 35.minutes

  belongs_to :user

  has_many :game_questions, dependent: :destroy

  validates :user, presence: true
  validates :current_level, numericality: {only_integer: true}, allow_nil: false
  validates :prize,
            presence: true,
            numericality: {greater_than_or_equal_to: 0, less_than_or_equal_to: PRIZES.last}

  scope :in_progress, -> { where(finished_at: nil) }

  def self.create_game_for_user!(user)
    transaction do
      game = create!(user: user)

      Question::QUESTION_LEVELS.each do |i|
        q = Question.where(level: i).order('RANDOM()').first
        ans = [1, 2, 3, 4]
        game.game_questions.create!(question: q, a: ans.shuffle!.pop, b: ans.shuffle!.pop, c: ans.shuffle!.pop, d: ans.shuffle!.pop)
      end
      game
    end
  end

  def previous_game_question
    game_questions.detect { |q| q.question.level == previous_level }
  end

  def current_game_question
    game_questions.detect { |q| q.question.level == current_level }
  end

  def previous_level
    current_level - 1
  end

  def finished?
    finished_at.present?
  end

  def time_out!
    if (Time.now - created_at) > TIME_LIMIT
      finish_game!(fire_proof_prize(previous_level), true)
      true
    end
  end

  def answer_current_question!(letter)
    return false if time_out! || finished?

    if current_game_question.answer_correct?(letter)
      if current_level == Question::QUESTION_LEVELS.max
        self.current_level += 1
        finish_game!(PRIZES[Question::QUESTION_LEVELS.max], false)
      else
        self.current_level += 1
        save!
      end

      true
    else
      finish_game!(fire_proof_prize(previous_level), true)
      false
    end
  end

  def take_money!
    return if time_out! || finished?
    finish_game!((previous_level > -1) ? PRIZES[previous_level] : 0, false)
  end


  # todo: дорогой ученик!
  # Код метода ниже можно сократиь в 3 раза с помощью возможностей Ruby и Rails,
  # подумайте как и реализуйте. Помните о безопасности и входных данных!
  #
  # Вариант решения вы найдете в комментарии в конце файла, отвечающего за настройки
  # хранения сессий вашего приложения. Вот такой вот вам ребус :)

  # Создает варианты подсказок для текущего игрового вопроса.
  # Возвращает true, если подсказка применилась успешно,
  # false если подсказка уже заюзана.
  #
  # help_type = :fifty_fifty | :audience_help | :friend_call
  def use_help(help_type)
    case help_type
    when :fifty_fifty
      unless fifty_fifty_used
        toggle!(:fifty_fifty_used)
        current_game_question.add_fifty_fifty
        return true
      end
    when :audience_help
      unless audience_help_used
        toggle!(:audience_help_used)
        current_game_question.add_audience_help
        return true
      end
    when :friend_call
      unless friend_call_used
        toggle!(:friend_call_used)
        current_game_question.add_friend_call
        return true
      end
    end

    false
  end

  def status
    return :in_progress unless finished?

    if is_failed
      # todo: дорогой ученик!
      # Если TIME_LIMIT в будущем изменится, статусы старых, уже сыгранных игр
      # могут измениться. Подумайте как это пофиксить!
      # Ответ найдете в файле настроек вашего тестового окружения
      if (finished_at - created_at) <= TIME_LIMIT
        :fail
      else
        :timeout
      end
    else
      if current_level > Question::QUESTION_LEVELS.max
        :won
      else
        :money
      end
    end
  end

  private

  # Метод завершатель игры
  # Обновляет все нужные поля и начисляет юзеру выигрыш
  def finish_game!(amount = 0, failed = true)

    # оборачиваем в транзакцию - игра заканчивается
    # и баланс юзера пополняется только вместе
    transaction do
      self.prize = amount
      self.finished_at = Time.now
      self.is_failed = failed
      user.balance += amount
      save!
      user.save!
    end
  end

  # По заданному уровню вопроса вычисляем вознаграждение за ближайшую несгораемую сумму
  # noinspection RubyArgCount
  def fire_proof_prize(answered_level)
    lvl = FIREPROOF_LEVELS.select { |x| x <= answered_level }.last
    lvl.present? ? PRIZES[lvl] : 0
  end

end
