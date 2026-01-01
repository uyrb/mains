
# zip内のほうのクラスは古い可能性あるので念のためアップ
# 2026-01-02
# -------------------------
# XXX m_button: M_RBUTTON XXX ここでボタン調整
# Clickable_state
class Button_state
  attr_accessor :pressed, :area_proc, :sym ,:win
  attr_accessor :on_push, :on_down, :on_release
  attr_accessor :on_hover, :on_leave
  attr_accessor :m_button
  attr_accessor :on_db_click , :last_push_time
  attr_accessor :true_proc
  alias on_db_push on_db_click
  alias on_db_push= on_db_click=
  # XXX アクティブ時だけ処理する判定の種類 XXX
  # true_proc || o.win.is_active || (未実装)o.win._ms_proc_private msg[:type] == "WM_MOUSE_INPUT"
  def initialize(sym: "button_state_class" , win: nil , m_button: M_LBUTTON , area_proc: nil, on_push: nil, on_down: nil, on_release: nil, on_hover: nil, on_leave: nil, on_db_click: nil,true_proc: nil)
    @sym     = sym
    @win     = win  # win.z だけ使う　 XXX
    @m_button = m_button
    @pressed = false
    @area_proc = area_proc || ->{[0,0,0,0]}
    @area      = [0,0,0,0]
    @on_down = on_down
    @on_push = on_push
    @on_release = on_release
    @on_hover = on_hover
    @on_leave = on_leave
    #
    @on_db_click = on_db_click
    @last_push_time = 0
    @true_proc = true_proc || ->{ true } # デフォルトでtrue
  end

  def is_leave?(lx, ly)
    @was_inside && is_hover?(lx, ly)
  end
  def is_hover?(lx, ly)
    inside?(lx, ly, *@area)
  end
  def active? = @true_proc.call
  def update(lx, ly)
    return false unless active?  # ← アクティブでなければ処理しない
    @area = @area_proc.call
    if is_hover?(lx, ly)
      @was_inside = true
      @on_hover&.call
    else
      if @was_inside
        @on_leave&.call   # ★ leave イベント実行
        @was_inside = false
      end
    end

    # --- ダブルクリック判定を完全に独立 ---
    if Input.mouse_push?(@m_button) && inside?(lx, ly, *@area)
      now = Time.now.to_f
      if (now - @last_push_time) < 0.3
        @on_db_click&.call
      end
      @last_push_time = now
    end

    if Input.mouse_push?( @m_button ) && inside?(lx, ly, *@area)
      @pressed = true
      @on_push&.call
    elsif @pressed && Input.mouse_down?( @m_button )
      @on_down&.call
    elsif @pressed && Input.mouse_release?( @m_button )
      @on_down&.call # 補正、on_push → on_releaseで down未処理は問題起きるため
      @on_release&.call if inside?(lx, ly, *@area)
      @pressed = false
    end
    return @pressed
  end

  def inside?(lx, ly, x0, y0, x1, y1)
    lx >= x0 && lx <= x1 && ly >= y0 && ly <= y1
  end

  # キーなどから「代理で押す」ための最小 API
  def _em_on_push(lx, ly)
    if inside?(lx, ly, *@area)
      @pressed = true
      @on_push&.call
    end
  end
  def _em_on_down = @on_push&.call
  def _em_on_release
    if @pressed
      @on_release&.call if inside?(lx, ly, *@area)
      @pressed = false
    end
  end
end # c

