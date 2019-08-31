class Board
  WINNING_LINES = [['A1', 'B1', 'C1'], ['A2', 'B2', 'C2'],
                   ['A3', 'B3', 'C3']] + # rows
                  [['A1', 'A2', 'A3'], ['B1', 'B2', 'B3'],
                   ['C1', 'C2', 'C3']] + # cols
                  [['A1', 'B2', 'C3'], ['C1', 'B2', 'A3']] # diagnals

  def initialize
    @squares = {}
    reset
  end

  def []=(square_key, marker)
    @squares[square_key].marker = marker
  end

  def [](square_key)
    @squares[square_key]
  end

  def square_is_marked?(square_key)
    marked_keys.include?(square_key)
  end

  def valid_square_key?(square_key)
    @squares.keys.include?(square_key)
  end

  def marked_keys
    @squares.keys.select { |key| @squares[key].marked? }
  end

  def unmarked_keys
    @squares.keys.select { |key| @squares[key].unmarked? }
  end

  def full?
    unmarked_keys.empty?
  end

  def threatened_lines
    threatened_lines = []

    WINNING_LINES.each do |line|
      markers = @squares.values_at(*line)
      threatened_lines << line if total_identical_makers(markers) == 2
    end

    threatened_lines
  end

  def line_dominated_by(player)
    threatened_lines.each do |line|
      markers = line.collect { |key| @squares[key].marker }
      return line if markers.include?(player.marker)
    end
    nil
  end

  def available_key_in_line(line)
    line.each do |key|
      return key if unmarked_keys.include? key
    end
  end

  def someone_won?
    !!winning_marker
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if total_identical_makers(squares) == 3
        return squares.first.marker
      end
    end
    nil
  end

  def reset
    (1..3).each do |row|
      ('A'..'C').each do |col|
        @squares["#{col}#{row}"] = Square.new
      end
    end
  end

  def draw
    puts "    A   B   C  "
    puts "  +---+---+---+"
    puts "1 | #{@squares['A1']} | #{@squares['B1']} | #{@squares['C1']} |"
    puts "  +---+---+---+"
    puts "2 | #{@squares['A2']} | #{@squares['B2']} | #{@squares['C2']} |"
    puts "  +---+---+---+"
    puts "3 | #{@squares['A3']} | #{@squares['B3']} | #{@squares['C3']} |"
    puts "  +---+---+---+"
  end

  private

  def total_identical_makers(squares)
    markers = squares.select(&:marked?).collect(&:marker)
    return 0 unless markers.any?
    return markers.size if markers.min == markers.max

    0
  end
end

class Square
  INITIAL_MARKER = " "

  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def to_s
    @marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end
end

class Player
  attr_accessor :score, :marker, :name

  def initialize(marker)
    @marker = marker
    @score = 0
  end

  def update_score(board)
    self.score += 1 if board.winning_marker == marker
  end
end

class Human < Player
  MARKER = 'X'

  def initialize
    super MARKER
  end
end

class Computer < Player
  MARKER = 'O'

  def initialize
    super MARKER
  end
end

class TTTGame
  GAMES_IN_SET = 5

  private

  attr_reader :board, :human, :computer, :current_player, :first_to_move

  public

  def initialize
    @board = Board.new
    @human = Human.new
    @computer = Computer.new
  end

  def play(first_player_choice = 'choose')
    self.first_to_move = first_player_choice
    clear
    display_welcome_message
    human.name = 'Human'
    computer.name = 'Computer'
    choose_marker
    choose_who_moves_first if first_to_move == 'choose'
    play_set
    display_set_result if set_winner?
    display_goodbye_message
  end

  private

  def choose_marker
    marker = nil

    loop do
      puts
      puts "Which player do you want to be? X or O?"
      marker = gets.chomp.upcase.strip
      break if ['X', 'O'].include?(marker)

      puts
      puts "Sorry, invalid choice."
    end

    human.marker = marker
    computer.marker = (marker == 'X' ? 'O' : 'X')
  end

  def first_to_move=(first_player_choice)
    case first_player_choice
    when human, 'human'
      @first_to_move = human
      @current_player = @first_to_move
    when computer, 'computer'
      @first_to_move = computer
      @current_player = @first_to_move
    else
      @first_to_move = 'choose'
    end
  end

  def choose_who_moves_first
    h_marker = human.marker
    c_marker = computer.marker
    marker = nil

    loop do
      puts
      puts "Who should go first?"
      puts "Choose: #{h_marker} or #{c_marker}"
      marker = gets.chomp.upcase.strip
      break if [h_marker, c_marker].include?(marker)

      puts
      puts "Sorry, invalid choice."
    end

    self.first_to_move = retrieve_player_of_mark(marker)
  end

  def retrieve_player_of_mark(marker)
    return human if marker == human.marker

    computer
  end

  def display_welcome_message
    puts "Welcome to Tic Tac Toe!"
  end

  def display_goodbye_message
    puts
    puts "Thanks for playing Tic Tac Toe! Goodbye!"
    puts
  end

  def display_board
    human_marker_message = "#{human.name}'s marker is #{human.marker}"
    computer_marker_message = "#{computer.name}'s marker is #{computer.marker}"
    puts "#{human_marker_message}. #{computer_marker_message}."
    puts ""
    board.draw
    puts ""
  end

  def clear_screen_and_display_board
    clear
    display_board
  end

  def play_set
    loop do
      clear_screen_and_display_board
      play_game
      human.update_score(board)
      computer.update_score(board)
      display_game_result
      display_score
      break if set_winner?
      break unless play_again?

      reset
      display_play_again_message
    end
  end

  def play_game
    loop do
      current_player_moves
      break if board.someone_won? || board.full?

      clear_screen_and_display_board
    end
  end

  def human_turn?
    @current_player == human
  end

  def human_moves
    choices = joinor(board.unmarked_keys, ', ', 'or')
    puts "Choose a square (#{choices}): "
    square_key = nil
    loop do
      square_key = gets.chomp.upcase
      break if valid_square?(square_key)

      puts "Sorry, that's not a valid choice."
    end

    board[square_key] = human.marker
  end

  def valid_square?(square_key)
    square_is_marked = board.square_is_marked?(square_key)
    valid_square_key = board.valid_square_key?(square_key)
    !square_is_marked && valid_square_key
  end

  def computer_moves
    computer_marker = computer.marker
    unmarked_keys = board.unmarked_keys
    computer_dominated_line = board.line_dominated_by(computer)
    human_dominated_line = board.line_dominated_by(human)

    if unmarked_keys.include?('B2')
      board['B2'] = computer_marker
    elsif computer_dominated_line
      computer_attack(computer_dominated_line)
    elsif human_dominated_line
      computer_attack(human_dominated_line)
    else
      board[unmarked_keys.sample] = computer_marker
    end
  end

  def computer_attack(line)
    available_key = board.available_key_in_line(line)
    board[available_key] = computer.marker
  end

  def current_player_moves
    if human_turn?
      human_moves
      @current_player = computer
    else
      computer_moves
      @current_player = human
    end
  end

  def set_winner?
    human.score >= 5 || computer.score >= 5
  end

  # rubocop:disable Metrics/AbcSize
  def display_score
    puts
    puts "+#{'SCORE'.center(33, '=')}+"
    puts "|#{human.name.center(16)}|#{computer.name.center(16)}|"
    puts "+----------------+----------------+"
    puts "|#{human.score.to_s.center(16)}|#{computer.score.to_s.center(16)}|"
    puts "+----------------+----------------+"
  end
  # rubocop:enable Metrics/AbcSize

  def display_game_result
    clear_screen_and_display_board

    case board.winning_marker
    when human.marker
      puts "You won the game!"
    when computer.marker
      puts "#{computer.name} won the game!"
    else
      puts "The game is a tie!"
    end
  end

  def display_set_result
    puts
    if human.score >= GAMES_IN_SET
      puts "You won the set!!!"
    else
      puts "#{computer.name} won the set!!!"
    end
  end

  def play_again?
    answer = nil
    loop do
      puts
      puts "Would you like to play again? (y/n)"
      answer = gets.chomp.downcase
      break if %w[y n].include? answer

      puts "Sorry, must be y or n"
    end

    answer == 'y'
  end

  def display_play_again_message
    puts "Let's play again!"
    puts ""
  end

  def clear
    system "clear"
  end

  def reset
    board.reset
    @current_player = first_to_move
    clear
  end

  def joinor(array, delimiter = ', ', final_join = 'or')
    case array.size
    when 0 then ''
    when 1 then array.first
    when 2 then array.join(" #{final_join} ")
    else
      array[-1] = "#{final_join} #{array.last}"
      array.join(delimiter)
    end
  end
end

game = TTTGame.new
game.play('choose')
