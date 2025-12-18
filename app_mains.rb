require "__dev/req" if $0 == __FILE__
require "dxruby"

# ---------------------------
# セルクラス
# ---------------------------
class App_mains_Mine_cell
  attr_accessor :x,:y,:mine,:state,:adj,:btn,:btn_r,:state_r_tmp,
  :img_revealed

  def initialize o, x, y, size
    @o = o
    @x = x
    @y = y
    @size = size
    @w = @h = size
    @adj = 0 # 「周囲8マスに地雷がいくつあるか」
    @font = Font.default
    b = 2
    # ---- 追加：事前生成する画像 ----
    @img_nomal = Image.new(@w, @h, [212,209,200])
    # 外枠（白）
    @img_nomal.line(1,0, @w-b,0, [255,255,255])
    @img_nomal.line(0,1, 0,@h-b, [255,255,255])
    # # 外枠（黒）mg_nomal.line(@w-1,0, @w-1,@h-1, [0,0,0])
    @img_nomal.line(1,@h-2, @w-b,@h-2,  [128,128,128])
    @img_nomal.line(1,@h-1, @w-b,@h-1, [0,0,0])
    @img_nomal.line(@w-2, 1, @w-2, @h-b, [128,128,128])
    @img_nomal.line(@w-2, 0, @w-2, @h-b, [128,128,128])
    @img_nomal.line(@w-1, 1, @w-1, @h-b, [0,0,0])
    @img_nomal.line(@w-0, 1, @w-1, @h-b, [0,0,0])
    # # 内枠（濃いグレー）
    # @img_nomal.line(1,1, @w-2,1, [128,128,128])
    # @img_nomal.line(1,1, 1,@h-2, [128,128,128])
    # @img_nomal.line(@w-2,1, @w-2,@h-2, [255,255,255])
    # @img_nomal.line(1,@h-2, @w-2,@h-2, [255,255,255])

    @img_revealed = Image.new(@w, @h, [191,191,191])
    @img_revealed.box(0, 0, @w-1, @h-1, [128,128,128])

    @img_down    = Image.new(@w, @h, [191,191,191])
    @img_hover   = Image.new(@w, @h, [220,220,220])
    # @img_hata    = Image.new(@w, @h, [105,40,40])
    @img_hata    = Image.new(@w, @h, [212,209,200])
    # @img_hata.draw_font(0,0,"Ｆ",@font)
    # 各段の厚み（3px）
    th = 3

    # 下段（いちばん大きい段）
    bot_w = (@w * 0.55).to_i
    x1 = (@w - bot_w) / 2 ;x2 = x1 + bot_w
    y2 = @h - 4           ;y1 = y2 - th
    @img_hata.box_fill(x1, y1, x2, y2, [0,0,0])

    # 中段
    mid_w = (@w * 0.20).to_i
    x1 = (@w - mid_w) / 2 ;x2 = x1 + mid_w
    y2 = y1           ;    y1 = y2 - th
    @img_hata.box_fill(x1, y1, x2, y2, [0,0,0])

    # 上段（いちばん細い段）
    top_w = (@w * 0.05).to_i
    x1 = (@w - top_w) / 2
    x2 = x1 + top_w
    y2 = y1
    y1 = y2 - th
    @img_hata.box_fill(x1, y1, x2, y2, [0,0,0])
#
    col = [205,0,0]

    # 中心座標
    cx = (@w / 2).to_i
    cy = (@h / 2).to_i

    # 三角形の縦全体サイズ（旗の高さ）
    total_h = 16  # だいたい今の 10 ～ +6 の範囲
    # 段数
    steps = 3
    steps.times do |i|
      # i = 0,1,2 と進むほど左に寄って短くなる
      ratio = 1.0 - (i.to_f / steps)   # 1.0 → 0.66 → 0.33 くらい
      # 各段の高さ位置（上端と下端）
      h_top = cy - (total_h * ratio * 0.6).to_i
      h_bottom = cy + (total_h * ratio * 0.4).to_i
      # 横方向（左向きに短くなる）
      x_right = cx - (i * 2)                # 少しずつ左へズレる
      thickness = 2                         # 棒の太さ
      x_left = x_right - (thickness)
      @img_hata.box_fill(
        x_left,
        h_top,
        x_right,
        h_bottom,
        col
      )
    end

    @img_hatena  = Image.new(@w, @h, [212,209,200])
    @img_hatena.draw_font(6,5,"？",@font,[0,0,205])
    @img_bomb_down  = Image.new(@w, @h, [105,0,0])
    @img_bomb_down.draw_font(10,5,"Ｘ",@font)
    @img_bomb    = Image.new(@w, @h, [212,209,200])
    @img_bomb.draw_font(10,5,"Ｘ",@font,[10,10,10])
    @img_bomb_hide    = @img_nomal.dup
    # @img_bomb_hide.draw_font(0,0,"*",@font)

    @state = "nomal"   # "nomal", "revealed", "bomb", "bomb_hide" "hata", "hatena"
    @state_r_tmp = "nomal"

    px = @x; py = @y; sz = @size
    w_main_con = Window_system_f.find_node_by_title(@o.win,"window_main_contents") if defined?(Window_system_f)

    @btn_r = Button_state.new(
      m_button: M_RBUTTON,
      area_proc: -> {
        # # 外に出すとおかしくなるので中に。
        x = px + (w_main_con&.x || 0)
        y = py + (w_main_con&.y || 0)
        [x, y, x+sz-1, y+sz-1]
      },
      on_push: -> {
        # 右クリック押した瞬間
        case @state
        when "nomal","bomb_hide"
          @state_r_tmp = @state
          @state = "hata"
        when "hata"
          @state = "hatena"
        when "hatena"
          @state = @state_r_tmp
        end
      },
    )
    @btn = Button_state.new(
      area_proc: -> {
        # XXX DEBUG # これは値渡し abs_x , abs_y = @o.abs_xy
        # 代入した時点でラムダキャプチャは値渡し、
        # 外に出す場合に参照を効かせるには、(w_main_con.x||0)がこのラムダ内に必要
        @btn_r.area_proc.call
      },
      on_push: -> {
      },
      on_leave: -> {
      },
      on_down: -> {
      },
      on_release: -> {
        case @state
        when "nomal"
          @state = "revealed"
          true_proc&.call(self)
        when "bomb_hide"
          game_over self,o
        end
      },
      on_hover: -> {
        # abs_x , abs_y = @o.abs_xy
        # xx = px + (abs_x || 0)
        # yy = py + (abs_y || 0)
        x = px + (w_main_con&.x || 0)
        y = py + (w_main_con&.y || 0)
        if @btn.pressed && (@state == "nomal" || @state == "bomb_hide")
          Window.draw( x,y, @img_down )
        elsif @state == "nomal" || @state == "bomb_hide"
          Window.draw( x,y, @img_hover )
        end
      },
    )
  end
  def game_over slf,o
    # 全セル公開
    o.cells.each do |c|
      if c.state == "bomb_hide"
        c.state = "bomb"   # 隠し爆弾 → 表示爆弾
      elsif c.state == "nomal"
        # c.state = "revealed"
      end
    end
    slf.state = "bomb_down"
    o.ren.draw_font(10,100,"game_over",Font.default)
    o.m_state = "game_over"
    o.Task do | zzz | zzz.delete_lazy 181 do # よくわからないけど１F遅らせる
      if true # button click
        o.m_state = "nomal"
        # o.app_mains_init.call
      end
    end ;zzz.Code{ } ;end
  end

  #マス展開（外から与えられる）
  attr_accessor :true_proc

  def draw ren
    imgs = {
      "nomal"      => :img_nomal,
      "revealed"   => :img_revealed,
      "down"       => :img_down,
      "bomb"       => :img_bomb,
      "bomb_hide"  => :img_bomb_hide,
      "bomb_down"  => :img_bomb_down,
      "hata"       => :img_hata,
      "hatena"     => :img_hatena
    }
    img_sym = imgs[@state]
    ren.draw(@x, @y, instance_variable_get("@#{img_sym}")) if img_sym
  end
  #
end # c




module Pattern_app_move
  module_function

  def app_mains
    bg_color       = [212,209,200]
    cell_up_color  = [191,191,191]   # 未開封
    cell_dn_color  = [191,191,191]   # 押された
    border_color   = [128,128,128]
    light_color    = [250,250,250]
    dark_color     = [10,10,10]


    # 難易度
    level_cycle = [
      { cols: 8,  rows: 8,  bomb_n: 10 },
      { cols: 16, rows: 10, bomb_n: 25 },
      { cols: 30, rows: 13, bomb_n: 70 },
    ].cycle
    cfg = level_cycle.next
    cell_size = 36
    cols   = cfg[:cols]
    rows   = cfg[:rows]
    bomb_n = cfg[:bomb_n]

    # cols = 8
    # rows = 8
    # bomb_n = 1
    offset_x = (400 - cols*cell_size) / 2
    offset_y = (400 - rows*cell_size) / 2 + 0
    offset_x = 55
    offset_y = 155

    num_font  = Font.new(30, "Tahoma", weight: 700)
    count_font = Font.new(50, "メイリオ", weight: 700)
    img = Image.new(100, 30,)
    img_icon_nomal = Image.new(img.width , img.height, bg_color)  # 黄色背景
    img_icon_nomal.draw_font(10,0,"(/・ω・)/",Font.default,[20,20,20])
    img_icon_down  = Image.new(img.width , img.height, bg_color)
    img_icon_down.draw_font(10,0,"(/ω＼)",Font.default,[20,20,20])
    img_icon_clear = Image.new(img.width , img.height, bg_color)
    img_icon_clear.draw_font(10,0,"(/・ω・)/",Font.default,[20,20,20])
    img_icon_game_over = Image.new(img.width , img.height, bg_color)
    img_icon_game_over.draw_font(10,0,"(ﾟДﾟ)",Font.default,[20,20,20])

    time_count ||= 0
    ->o,oo,user{
      o.Scarlet[(__FILE__ + __LINE__.to_s)][0] ||= begin
        o.extend Module.new{
          attr_accessor :cells , :app_mains_init,:flood,
          :mado_init , :m_state, :mado_cycle
        }
        w_main_con = Window_system_f.find_node_by_title(o.win,"window_main_contents") if defined?(Window_system_f)

        o.mado_cycle = Button_state.new(
          m_button: M_MBUTTON,
          area_proc: -> {
            abs_x, abs_y = (w_main_con&.x||0), (w_main_con&.y||0)
            xx = (o.ren.width - img.width) / 2
            yy = 40
            [ abs_x + xx, abs_y + yy,
              abs_x + xx + img.width,abs_y + yy + img.height ]
          },
          on_push: -> {
          },
          on_release: -> {
            cfg = level_cycle.next
            cols   = cfg[:cols]
            rows   = cfg[:rows]
            bomb_n = cfg[:bomb_n]
            time_count = 0
            o.m_state = "nomal"
            o.app_mains_init.call
            # Window_system_f.find_node_by_title( o.win ,"window_title")&.then do |wt|
            #   wt.wind.set_size( o.ren.width, o.ren.height, false)
            # end
          },
        )
        o.m_state = "nomal"
        o.mado_init = Button_state.new(
          area_proc: -> {
            # Window.draw_ex(xx,yy,img,{z:999})
            abs_x, abs_y = (w_main_con&.x||0), (w_main_con&.y||0)
            xx = (o.ren.width - img.width) / 2
            yy = 40
            # o.ren.draw(xx,yy,img)
            # Window.draw( xx+abs_x , yy+abs_y, img )
            case o.m_state
            when "nomal"
              o.ren.draw( xx,yy, img_icon_nomal )
            when "game_over"
              o.ren.draw( xx,yy, img_icon_game_over )
            when "game_clear"
              o.ren.draw( xx,yy, img_icon_clear )
            end
            count = o.cells.count { |c| c.state == "hata" }

            xxx = (o.ren.width) / 2
            # 初期化（1回だけ）
            @frame ||= 0
            @frame += 1
            if o.m_state != "game_clear"
              time_count = (time_count + 1)  if @frame % 60 == 0
            end
            text = format("%03d", time_count)
#
            draw_x = (xxx - 130) - count_font.get_width(text) / 2
            o.ren.draw_font(draw_x, yy, text, count_font, color:[50,40,40])
#
            text = format("%03d", bomb_n-count)

            draw_x = (xxx + 135) - count_font.get_width(text) / 2
            o.ren.draw_font(draw_x, yy, text, count_font, color:[50,40,40])
            # o.ren.draw_font( xxx + 130 , yy, text, count_font, color:[50,40,40] )
            [
              abs_x + xx, abs_y + yy,
              abs_x + xx + img.width,
              abs_y + yy + img.height
            ]
          },
          on_push: -> {
          },
          on_leave: -> {
          },
          on_release: -> {
            o.app_mains_init.call
          },
          on_down: -> {
            xx = (o.ren.width - img.width) / 2
            yy = 40
            o.ren.draw(xx,yy,img_icon_down)
          },
          on_hover: -> {
          },
        )

        o.app_mains_init = ->{
          o.m_state = "nomal"
          time_count = 0

          aa = cols*cell_size + 105
          bb = rows*cell_size + 105
          o.ren.resize aa , bb + 100
          o.ren.draw_box_fill(0,0,o.ren.width,o.ren.height,bg_color)

          Window_system_f.find_node_by_title( o.win ,"window_title")&.then do |wt|
            wt.wind.set_size( o.ren.width, o.ren.height, false)
          end if defined?(Window_system_f)
          # セル生成
          o.cells = []
          rows.times do |ry|
            cols.times do |rx|
              cx = offset_x + rx*cell_size
              cy = offset_y + ry*cell_size
              o.cells << App_mains_Mine_cell.new(o, cx, cy, cell_size)
            end
          end
          o.cells.sample(bomb_n).each{|c| c.state = "bomb_hide" }

        # 隣接数計算
        rows.times do |ry|
          cols.times do |rx|
            idx = ry*cols + rx
            c = o.cells[idx]
            if c.state == "bomb"
              next
            end
            adj = 0
            (-1..1).each do |dy|
              (-1..1).each do |dx|
                next if dx==0 && dy==0
                nx = rx+dx
                ny = ry+dy
                next if nx<0 || ny<0 || nx>=cols || ny>=rows
                adj += 1 if ["bomb", "bomb_hide"].include?(o.cells[ny*cols + nx].state)
              end
            end
            c.adj = adj
            nc = c
            # 数字描画（adj > 0 のときだけ描く）
            if nc.adj > 0
              # 好みで色を分ける（XP風）
              num_color = case nc.adj
                when 1 then [0, 0, 205]
                when 2 then [0, 128, 0]
                when 3 then [205, 0, 0]
                when 4 then [0, 0, 128]
                when 5 then [128, 0, 0]
                when 6 then [0, 128, 128]
                when 7 then [0, 0, 0]
                when 8 then [128, 128, 128]
              end
              # num_color = NUM_COLOR[nc.adj]
              nc.img_revealed.draw_font(10, 0, nc.adj.to_s, num_font, num_color)
            end
          end
        end
        # マス展開処理（左クリックで開いた直後に呼ばれる）
        o.flood = ->cell{
          # 展開してはいけない状態
          return if ["hata","hatena","bomb_hide","bomb"].include?(cell.state)
          # 開始セルを開く（呼び出し前に既に revealed になっている場合でも OK）
          cell.state = "revealed" unless cell.state == "revealed"
          return if cell.adj > 0
          queue = [cell]
          visited = {}
          while queue.any?
            cc = queue.shift
            next if visited[cc.object_id]
            visited[cc.object_id] = true

            idx = o.cells.index(cc)
            rx = idx % cols
            ry = idx / cols
            (-1..1).each do |dy|
              (-1..1).each do |dx|
                next if dx==0 && dy==0
                nx = rx+dx
                ny = ry+dy
                next if nx<0 || ny<0 || nx>=cols || ny>=rows
                nc = o.cells[ny*cols + nx]
                # 展開時に state を revealed に
                unless ["hata","hatena","bomb_hide","bomb"].include?(nc.state)
                  nc.state = "revealed"
                  nc.img_revealed# これに数値書き込み
                end
                if nc.adj == 0 && !nc.mine
                  queue << nc
                end
              end
            end

          end # while
        }
          # 各セルに flood を割り当て
          o.cells.each{|c|
            c.true_proc = ->cell{
              o.flood.call(cell) if cell.adj == 0 && !cell.mine
            }
          }
        }
        o.app_mains_init.call

        true
      end
      # --------------------------------
      o.ren.draw_box_fill(0,0,o.ren.width,o.ren.height,bg_color)
      o.mado_init.update(Input.mouse_pos_x , Input.mouse_pos_y)
      o.mado_cycle.update(Input.mouse_pos_x , Input.mouse_pos_y)

      o.cells.each{|c| c.btn.update(Input.mouse_pos_x , Input.mouse_pos_y) }
      o.cells.each{|c| c.btn_r.update(Input.mouse_pos_x , Input.mouse_pos_y) }

      o.cells.each{|c| c.draw(o.ren) }

      # XXX クリア判定
      # XXX "revealed" 以外のセルの個数 ==　bomb_nの数==hataの数
      not_revealed = o.cells.count { |c| c.state != "revealed" }
      # 旗（hata）の数
      flag_n = o.cells.count { |c| c.state == "hata" }
      clear = (not_revealed == bomb_n) && (bomb_n == flag_n)
      if clear
      # if flag_count_ok && all_opened
          xx = (o.ren.width - img.width) / 2
        o.ren.draw_font(xx,10,"クリア",Font.default)
        o.m_state = "game_clear"
      end

      x_pos = 30
      y_pos = 130
      # hidar
      o.ren.draw_box_fill(x_pos,y_pos,x_pos+5,o.ren.height-30,[255,255,255])
      o.ren.draw_box_fill(x_pos+5,y_pos,x_pos+20,o.ren.height-40,[212,209,200])
      o.ren.draw_box_fill(x_pos+20,y_pos,x_pos+25,o.ren.height-25,[128,128,128])
      # ue
      o.ren.draw_box_fill(x_pos, y_pos, o.ren.width-30, y_pos+5, [255,255,255])
      o.ren.draw_box_fill(x_pos+10, y_pos+5, o.ren.width-30, y_pos+20, [212,209,200])
      o.ren.draw_box_fill(x_pos+20, y_pos+20, o.ren.width-50, y_pos+25, [128,128,128])
      # migi
      mx_pos = o.ren.width - 50
      o.ren.draw_box_fill(mx_pos , y_pos+20, mx_pos+5, o.ren.height-46, [255,255,255])
      o.ren.draw_box_fill(mx_pos + 5, y_pos+30, mx_pos+20, o.ren.height - 40, [212,209,200])
      o.ren.draw_box_fill(mx_pos + 20, y_pos+0, mx_pos+25, o.ren.height - 25, [128,128,128])
      #sita
      my_pos = o.ren.height - 50
      o.ren.draw_box_fill(x_pos+20, my_pos, o.ren.width-50, my_pos+5, [255,255,255])
      o.ren.draw_box_fill(x_pos+10, my_pos+5, o.ren.width-50, my_pos+20, [212,209,200])
      o.ren.draw_box_fill(x_pos, my_pos+20, o.ren.width-30, my_pos+25, [128,128,128])

      # button space
      # yb_h = 120
      # y_pos = 30
      # # hidar
      # o.ren.draw_box_fill(x_pos,y_pos,x_pos+5,yb_h,[255,255,255])
      # o.ren.draw_box_fill(x_pos+5,y_pos,x_pos+20,yb_h-40,[212,209,200])
      # o.ren.draw_box_fill(x_pos+20,y_pos,x_pos+25,yb_h-25,[128,128,128])
      #
      # mado_init


      # abs_x, abs_y = o.abs_xy
      # xx = (o.ren.width - img.width) / 2
      # yy = 40
      # o.ren.draw(xx,yy,img)
    #   case o.m_state
    #   when "nomal"
    #     Window.draw( xx+abs_x , yy+abs_y, img_icon_nomal )
    #   when "down"
    #     Window.draw( xx+abs_x , yy+abs_y, img_icon_down )
    # end

    }
  end
end
