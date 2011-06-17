--[[
      L�VEly Snake by Joshua Button
      
      TODOS:
        * Add countdown on unpause
        * Better way to handle game states
        * Main menu with options screen for difficulty and other options
        * Keyboard controls on menus
        * Option to turn wall collision on or off
        * Option to change game colors?
        * Mouse controls (snake travels twords cursor position)
        * Multiple food items? Powerups?
        * Score board with high scores
        * Sound effects?
        * Clean up code
                                                                              ]]

love.filesystem.load("lib/middleclass.lua")()

love.filesystem.load("classes/engine/actor.lua")()
love.filesystem.load("classes/engine/level.lua")()
love.filesystem.load("classes/snake/snake.lua")()

love.filesystem.load("engine.lua")()
love.filesystem.load("menus.lua")()
love.filesystem.load("snake.lua")()

--
----- LOVE FUNCTIONS -----
--

function love.load()
  math.randomseed(os.time())
  math.random() -- Numbers wont be random on the first call for some reason
  
  max_width = 800
  max_height = 600
  game_state = "main_menu" -- main_menu, options_menu, running, paused, game_over
  
  small_font = love.graphics.newFont(14)
  medium_font = love.graphics.newFont(20)
  large_font = love.graphics.newFont(32)
  
  x_start = 32 * 12 --hardcoded, this should be set depending on resolution
  y_start = 32 * 8
  
  init_snake()
  
  -- Disable key repeating
  love.keyboard.setKeyRepeat(0, 100)
  
  resolutions = {
    {current=true, x=800, y=600},
    {current=false, x=1440, y=700}
  }
  
  colors = {
    red = {200, 0, 70, 255},
    white = {255, 255, 255, 255}
  }
  
  difficulty = {
    very_easy = 400,
    easy = 200,
    normal = 100,
    hard = 50,
    very_hard = 20,
    menu = 0
  }
 
  ui = {
    common = {
      y_title_loc = max_height * 0.05, -- Vertical spacing of the title as a percentage from the top
      y_first_loc = 0.30, -- Vertical location of the first menu item
      y_vert_space = 0.06 -- changed from 0.05 to 0.06, test more
    },
    main_menu = {
      title = "LOVEly Snake",
      "New Game",
      "Options",
      "Quit",
    },
    options_menu = {
      title = "Options",
      difficulty_buttons = {
        width = max_width * 0.09,
        height = max_height * 0.05,
        very_easy = {str="V.Easy", x_pos=max_width * 0.25, y_pos=max_height * 0.35}, -- these need to be updated on screen resize
        easy = {str="Easy", x_pos=max_width * 0.35, y_pos=max_height * 0.35},
        normal = {str="Normal", x_pos=max_width * 0.45, y_pos=max_height * 0.35},
        hard = {str="Hard", x_pos=max_width * 0.55, y_pos=max_height * 0.35},
        very_hard = {str="V.Hard", x_pos=max_width * 0.65, y_pos=max_height * 0.35}
      },
      "Difficulty",
      function () display_horizontal_buttons() end, -- function to print difficulty buttons
      "Back"
    }
  }
  
  if love.filesystem.exists("options.cfg") then
    love.filesystem.load("options.cfg")()
  else
    current_difficulty = difficulty.normal
    update_options_file()
  end
  
  hovering_over = nil
  block_size = 32 -- Just realized this only works with 10,20,25,50,100 need to think more on collision and resolution
  speed = difficulty.menu -- In milliseconds
  menu_item_loc = 0.30
  menu_item_space = 0.05
  
  level = Level:new()
  level:load_level('/resources/levels/snake_1.lua', 32, 32)
end

function love.update(dt)
  love.timer.sleep(speed)
  
  if game_state == "main_menu" then
    speed = difficulty.menu
    return
  elseif game_state == "options_menu" then
    return
  elseif game_state == "paused" then
    return
  elseif game_state == "game_over" then
    return
  end
  
  speed = current_difficulty
    level:update_level(dt)
  generate_food()
  move_snake(dt)
end

function love.draw()
  --love.graphics.scale(1.6, 1.5)
  level:draw_level()
  love.graphics.setColor(colors.white)
  -- Get the current x,y locations of the mouse cursor
  local mouse_x = love.mouse.getX()
  local mouse_y = love.mouse.getY()
  
  if game_state == "main_menu" then
    draw_main_menu(mouse_x, mouse_y)
    
  elseif game_state == "options_menu" then
    draw_options_menu(mouse_x, mouse_y)
    
  elseif game_state == "paused" then
    love.graphics.setColor(colors.white)
    love.graphics.printf("PAUSED", 0, max_height / 2, max_width, 'center')
    
  elseif game_state == "game_over" then
    -- Game over
    draw_main_menu(mouse_x, mouse_y)
    
  elseif game_state == "running" then
    --[[ -- drawing in level for now
    -- Draw the snake food
    if next(snake_food) ~= nil then
      love.graphics.setColor(colors.red)
      love.graphics.rectangle("fill", snake_food[1]["x"], snake_food[1]["y"], block_size, block_size)
    end]]
    
    -- Draw the snake body
    for key, value in pairs(snake_loc) do
      love.graphics.setColor(75, 50, 175, 255)
--love.graphics.print(key, 400, 200)
--love.graphics.print(value.x, 400, 250)
--love.graphics.print(value.y, 400, 300)
      --love.graphics.rectangle("fill", value.x, value.y, block_size, block_size)
    end
    
    love.graphics.setColor(colors.white)
    
  end
end

function love.mousepressed(x, y, button)
  if button == 'l' then
    -- button 1 clicked at position x, y
  end
end

function love.mousereleased(x, y, button) -- needs updated to work with menus, temp solution for now.
  if button == 'l' then
    
    if game_state == "main_menu" then
      if hovering_over == "New Game" then
        print("clicked new game")
        game_state = "running"
        if speed == "menu" then
          speed = current_difficulty -- should set to options value from file
        end
      end
      if hovering_over == "Options" then
        print("clicked options")
        game_state = "options_menu"
      end
      if hovering_over == "Quit" then
        print("clicked quit")
        love.event.push('q')
      end
      
    elseif game_state == "options_menu" then
      for key, value in next, ui.options_menu.difficulty_buttons, nil do
        if key ~= "width" and key ~= "height" then
          --print(key, value)
          if mouse_inside("both", x, y, ui.options_menu.difficulty_buttons[key].x_pos,
                          ui.options_menu.difficulty_buttons[key].y_pos,
                          ui.options_menu.difficulty_buttons.width,
                          ui.options_menu.difficulty_buttons.height) then
            print("Clicked " .. key)
            current_difficulty = difficulty[key]
            update_options_file()
          end
        end
      end
      if hovering_over == "Back" then
        print("clicked back")
        game_state = "main_menu"
      end
    end
    
  end
end

function love.keypressed(key, unicode)
  if key == 'return' then
    print("The return key was pressed.")
    if game_state ~= "paused" then
      game_state = "paused"
    else
      game_state = "running"
    end
  elseif key == 'up' and snake_direction ~= 'down' then
    snake_direction = "up"
  elseif key == 'down' and snake_direction ~= 'up' then
    snake_direction = "down"
  elseif key == 'left' and snake_direction ~= 'right' then
    snake_direction = "left"
  elseif key == 'right' and snake_direction ~= 'left' then
    snake_direction = "right"
  end
  
  -- Debug
  if key == 'i' then
    local tmp = level:get_coords("world", snake_loc["head"]["x"], snake_loc["head"]["y"])
    table.insert(snake_loc, {x=tmp.x * 32, y=tmp.y * 32, dir=snake_direction}) --push?
    print("Inserted body at coords x: " .. tmp.x * 32 .. " y: " .. tmp.y * 32)
  elseif key == 'r' then
    table.remove(snake_loc) --pop?
  elseif key == 'g' then
    -- testing window resizing
    for i = 1, #resolutions do
      if resolutions[i].current == true and i ~= #resolutions then
        resolutions[i].current = false
        resolutions[i+1].current = true
        love.graphics.setMode(resolutions[i+1].x, resolutions[i+1].y, false, true, 0)
        max_width = resolutions[i+1].x
        max_height = resolutions[i+1].y
        break -- eww, might rewrite
      elseif resolutions[i].current == true and i == #resolutions then
        resolutions[i].current = false
        resolutions[1].current = true
        love.graphics.setMode(resolutions[1].x, resolutions[1].y, false, true, 0)
        max_width = resolutions[1].x
        max_height = resolutions[1].y
        break
      end
    end
    --love.graphics.translate( 200, 200 )
  elseif key == 'f' then
    love.graphics.toggleFullscreen( )
  elseif key == 'm' then
    display_menu_items(ui.main_menu, love.mouse.getX(), love.mouse.getY())
  elseif key == 'escape' then
    game_state = "main_menu"
  elseif key == 'w' then
    --print(love.filesystem.getSaveDirectory())
  elseif key == 'd' then
    --act = Actor:new("testing")
    --act:foobar()
  end
end

function love.keyreleased(key, unicode)
  if key == 'b' then
    text = "The B key was released."
  elseif key == 'a' then
    a_down = false
  end
end

function love.focus(f)
  if not f then
    print("LOST FOCUS")
    if game_state == "running" then
      game_state = "paused"
    end
  else
    print("GAINED FOCUS")
  end
end

function love.quit()
  print("quit()")
end

--
----- OTHER FUNCS -----
--

-- checks to see if the mosue is clicked or hovered inside a rectangle
function mouse_inside(checking, x_mouse, y_mouse, x_pos, y_pos, width, height)
  local valid_x = false
  local valid_y = false

  if x_mouse >= x_pos and x_mouse < x_pos + width then
    valid_x = true
  end
  if y_mouse >= y_pos and y_mouse < y_pos + height then
    valid_y = true
  end
  
  if checking == "x_only" then
    return valid_x
  elseif checking == "y_only" then
    return valid_y
  elseif checking == "both" then
    if valid_x == true and valid_y == true then
      return true
    else
      return false
    end
  end
end

-- string, y position
function print_centered(s, y)
  love.graphics.printf(s, 0, y, max_width, 'center')
end
