"""Sinh 5 banner pixel động cho khung NGANG của màn Trang chủ.

Bản cũ vẽ cho khung 393x280; băng ảnh hiện tại là 2.4:1 nên gần 40% chiều cao
bị xén, cắt đúng vào chỗ có nội dung. Ở đây mọi thứ được bố trí lại trên lưới
131x55 ô (ô 3px -> 393x165), tức vẽ thẳng cho tỉ lệ đang dùng.
"""

from PIL import Image, ImageDraw

CELL = 3
GW, GH = 131, 55
W, H = GW * CELL, GH * CELL
FRAMES = 12
DURATION = 80

# ---------------------------------------------------------------- bảng màu
INK = (15, 23, 42)
WHITE = (255, 255, 255)
SKY = (56, 189, 248)
SKY_DEEP = (14, 165, 233)
BLUE = (37, 99, 235)
BLUE_DARK = (30, 58, 138)
BLUE_MID = (29, 78, 216)
GREEN = (34, 197, 94)
GREEN_DARK = (22, 163, 74)
YELLOW = (250, 204, 21)
AMBER = (245, 158, 11)
RED = (220, 38, 38)
PINK = (244, 114, 182)
PURPLE = (167, 139, 250)
PAPER = (254, 252, 232)
RULE = (191, 219, 254)
SKIN = (253, 224, 171)
BROWN = (146, 64, 14)

# ------------------------------------------------------------------- font
# Mỗi ký tự là lưới 5x7.
FONT = {
    'A': ('.###.', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'),
    'B': ('####.', '#...#', '#...#', '####.', '#...#', '#...#', '####.'),
    'C': ('.####', '#....', '#....', '#....', '#....', '#....', '.####'),
    'D': ('####.', '#...#', '#...#', '#...#', '#...#', '#...#', '####.'),
    'E': ('#####', '#....', '#....', '####.', '#....', '#....', '#####'),
    'G': ('.###.', '#...#', '#....', '#.###', '#...#', '#...#', '.###.'),
    'H': ('#...#', '#...#', '#...#', '#####', '#...#', '#...#', '#...#'),
    'I': ('#####', '..#..', '..#..', '..#..', '..#..', '..#..', '#####'),
    'K': ('#...#', '#..#.', '#.#..', '##...', '#.#..', '#..#.', '#...#'),
    'M': ('#...#', '##.##', '#.#.#', '#...#', '#...#', '#...#', '#...#'),
    'N': ('#...#', '##..#', '#.#.#', '#..##', '#...#', '#...#', '#...#'),
    'O': ('.###.', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'),
    'P': ('####.', '#...#', '#...#', '####.', '#....', '#....', '#....'),
    'Q': ('.###.', '#...#', '#...#', '#...#', '#.#.#', '#..#.', '.##.#'),
    'R': ('####.', '#...#', '#...#', '####.', '#.#..', '#..#.', '#...#'),
    'S': ('.####', '#....', '#....', '.###.', '....#', '....#', '####.'),
    'T': ('#####', '..#..', '..#..', '..#..', '..#..', '..#..', '..#..'),
    'U': ('#...#', '#...#', '#...#', '#...#', '#...#', '#...#', '.###.'),
    'V': ('#...#', '#...#', '#...#', '#...#', '#...#', '.#.#.', '..#..'),
    'W': ('#...#', '#...#', '#...#', '#...#', '#.#.#', '##.##', '#...#'),
    'Y': ('#...#', '#...#', '.#.#.', '..#..', '..#..', '..#..', '..#..'),
    'Z': ('#####', '....#', '...#.', '..#..', '.#...', '#....', '#####'),
    '0': ('.###.', '#...#', '#..##', '#.#.#', '##..#', '#...#', '.###.'),
    '1': ('..#..', '.##..', '..#..', '..#..', '..#..', '..#..', '.###.'),
    '5': ('#####', '#....', '####.', '....#', '....#', '#...#', '.###.'),
    '+': ('.....', '..#..', '..#..', '#####', '..#..', '..#..', '.....'),
    '!': ('..#..', '..#..', '..#..', '..#..', '..#..', '.....', '..#..'),
    '?': ('.###.', '#...#', '....#', '..##.', '..#..', '.....', '..#..'),
    ' ': ('.....', '.....', '.....', '.....', '.....', '.....', '.....'),
}


class Canvas:
    """Khung vẽ theo Ô, không theo điểm ảnh — mọi toạ độ dưới đây là ô."""

    def __init__(self, bg):
        self.img = Image.new('RGB', (W, H), bg)
        self.d = ImageDraw.Draw(self.img)

    def rect(self, x, y, w, h, color):
        if w <= 0 or h <= 0:
            return
        self.d.rectangle(
            [x * CELL, y * CELL, (x + w) * CELL - 1, (y + h) * CELL - 1],
            fill=color,
        )

    def text(self, s, x, y, color, scale=1, spacing=1):
        for ch in s:
            glyph = FONT.get(ch.upper())
            if glyph:
                for gy, row in enumerate(glyph):
                    for gx, cellv in enumerate(row):
                        if cellv == '#':
                            self.rect(x + gx * scale, y + gy * scale, scale, scale, color)
            x += (5 + spacing) * scale

    @staticmethod
    def text_w(s, scale=1, spacing=1):
        return len(s) * (5 + spacing) * scale - spacing * scale

    def star(self, x, y, color, size=2):
        """Ngôi sao 4 cánh, tâm ở (x, y)."""
        self.rect(x - size, y, size * 2 + 1, 1, color)
        self.rect(x, y - size, 1, size * 2 + 1, color)
        self.rect(x - 1, y - 1, 3, 3, color)

    def tick(self, x, y, color, scale=1):
        for i in range(3):
            self.rect(x + i * scale, y + i * scale, scale, scale, color)
        for i in range(5):
            self.rect(x + (3 + i) * scale, y + (2 - i) * scale, scale, scale, color)


# ------------------------------------------------------- 38 · chọn đáp án
def scene_quiz(f):
    c = Canvas(BLUE_DARK)
    c.rect(0, 0, GW, 18, (23, 46, 110))
    for i in range(0, GW, 8):                       # vệt nền mờ cho đỡ phẳng
        c.rect(i, 0, 3, GH, (26, 52, 122))
    c.rect(0, 18, GW, GH - 18, BLUE_DARK)

    title = 'QUIZ TIME'
    c.text(title, (GW - Canvas.text_w(title, 2)) // 2, 3, WHITE, scale=2)

    # Bốn đáp án xếp thành hai cột: khung ngang thì bốn hàng dọc sẽ mảnh như chỉ.
    picked = 2                                      # chốt câu C
    cursor = min(f // 2, 3)                         # con trỏ chạy A -> D
    locked = f >= 8
    for i in range(4):
        col, row = i % 2, i // 2
        x = 8 + col * 60
        y = 21 + row * 14
        active = (i == cursor and not locked) or (locked and i == picked)
        if locked and i == picked:
            box, edge = (22, 163, 74), (134, 239, 172)
        elif active:
            box, edge = (37, 99, 235), YELLOW
        else:
            box, edge = (23, 46, 110), (55, 90, 170)
        c.rect(x, y, 54, 11, edge)
        c.rect(x + 1, y + 1, 52, 9, box)
        c.text('ABCD'[i], x + 3, y + 2, WHITE)
        c.rect(x + 12, y + 4, 30 - (i * 3), 3, (147, 178, 235) if not active else WHITE)
        if locked and i == picked:
            c.tick(x + 45, y + 3, WHITE)

    if locked:                                      # tia sáng ăn mừng
        for k, (sx, sy) in enumerate([(6, 12), (124, 14), (66, 50), (18, 48), (112, 46)]):
            if (f + k) % 2 == 0:
                c.star(sx, sy, YELLOW)
    return c.img


# --------------------------------------------------------- 42 · điểm 10
def scene_great(f):
    c = Canvas(BLUE_DARK)
    c.rect(0, 30, GW, GH - 30, BLUE)                # sàn
    c.rect(0, 28, GW, 2, BLUE_MID)

    txt = 'GREAT!'
    c.text(txt, 8, 8, WHITE, scale=2)

    # Kim tuyến rơi, lặp trọn vòng theo 12 khung nên không giật lúc quay lại.
    confetti = [(12, RED), (26, YELLOW), (40, GREEN), (54, PINK), (70, WHITE),
                (84, YELLOW), (98, PURPLE), (112, RED), (120, GREEN)]
    for i, (x, color) in enumerate(confetti):
        y = (f * 4 + i * 5) % 52
        c.rect(x, y, 2, 3, color)

    # Bạn học sinh giơ tờ giấy điểm 10.
    bob = 1 if f % 4 < 2 else 0                     # nhún người
    bx, by = 86, 20 - bob
    c.rect(bx + 3, by, 8, 7, SKIN)                  # đầu
    c.rect(bx + 2, by - 2, 10, 3, BROWN)            # tóc
    c.rect(bx + 5, by + 3, 2, 1, INK)
    c.rect(bx + 9, by + 3, 2, 1, INK)
    c.rect(bx + 2, by + 7, 10, 10, RED)             # áo
    c.rect(bx, by + 8, 2, 6, SKIN)                  # tay trái
    c.rect(bx + 12, by + 5 - bob, 2, 6, SKIN)       # tay phải giơ lên
    c.rect(bx + 3, by + 17, 3, 6, BLUE_MID)         # chân
    c.rect(bx + 8, by + 17, 3, 6, BLUE_MID)

    px, py = bx + 14, by + 1 - bob                  # tờ giấy
    c.rect(px, py, 18, 15, WHITE)
    c.rect(px + 1, py + 1, 16, 3, RED)
    c.text('10', px + 3, py + 6, RED)

    for k, (sx, sy) in enumerate([(20, 34), (48, 30), (74, 38), (118, 32)]):
        if (f + k) % 3 != 0:
            c.star(sx, sy, YELLOW)
    return c.img


# ---------------------------------------------------- 44 · nhóm bạn vẫy tay
def scene_friends(f):
    c = Canvas(SKY)
    # Trời xuống màu theo ba dải sát nhau: một mảng phẳng thì nhạt nhẽo, mà
    # chia hai tông chênh nhau nhiều lại thành một vệt ngang trông như lỗi.
    c.rect(0, 0, GW, 12, (186, 230, 253))
    c.rect(0, 12, GW, 12, (125, 211, 252))
    c.rect(0, 36, GW, GH - 36, GREEN)               # cỏ
    c.rect(0, 34, GW, 2, (74, 222, 128))

    sun_x = 116                                     # mặt trời + tia nhấp nháy
    c.rect(sun_x - 4, 4, 9, 9, YELLOW)
    c.rect(sun_x - 5, 5, 11, 7, YELLOW)
    c.rect(sun_x - 3, 3, 5, 11, YELLOW)
    for k, (dx, dy) in enumerate([(-8, 8), (8, 8), (0, -6), (0, 14)]):
        if (f + k) % 3 != 0:
            c.rect(sun_x + dx, 4 + dy, 2, 2, YELLOW)

    for i, (cx, speed) in enumerate([(10, 1), (60, 1), (95, 1)]):   # mây trôi
        x = (cx + f * speed * 2) % (GW + 20) - 10
        c.rect(x, 6 + i * 3, 12, 4, WHITE)
        c.rect(x + 3, 4 + i * 3, 7, 3, WHITE)

    shirts = [RED, YELLOW, PURPLE]
    for i, shirt in enumerate(shirts):
        bx = 24 + i * 30
        by = 20
        up = (f + i * 4) % 8 < 4                    # vẫy tay lệch nhịp
        c.rect(bx + 3, by, 8, 7, SKIN)
        c.rect(bx + 2, by - 2, 10, 3, INK if i != 1 else BROWN)
        c.rect(bx + 5, by + 3, 2, 1, INK)
        c.rect(bx + 9, by + 3, 2, 1, INK)
        c.rect(bx + 2, by + 7, 10, 9, shirt)
        c.rect(bx, by + 8, 2, 6, SKIN)
        if up:
            c.rect(bx + 12, by - 1, 2, 8, SKIN)     # tay giơ cao
        else:
            c.rect(bx + 12, by + 7, 2, 6, SKIN)
        c.rect(bx + 3, by + 16, 3, 5, BLUE_MID)
        c.rect(bx + 8, by + 16, 3, 5, BLUE_MID)

        hy = 12 - ((f + i * 3) % 6)                 # tim bay lên
        if (f + i) % 6 < 4:
            c.rect(bx + 13, hy, 2, 2, PINK)
            c.rect(bx + 16, hy, 2, 2, PINK)
            c.rect(bx + 14, hy + 2, 3, 2, PINK)
    return c.img


# ------------------------------------------------- 35 · cổng trường buổi sáng
def scene_school(f):
    c = Canvas(SKY)
    c.rect(0, 0, GW, 10, (186, 230, 253))
    c.rect(0, 10, GW, 10, (125, 211, 252))
    c.rect(0, 38, GW, GH - 38, GREEN_DARK)          # sân cỏ
    c.rect(0, 36, GW, 2, GREEN)

    for i, cx in enumerate([12, 74]):               # mây
        x = (cx + f * 2) % (GW + 24) - 12
        c.rect(x, 5 + i * 4, 13, 4, WHITE)
        c.rect(x + 4, 3 + i * 4, 6, 3, WHITE)

    c.rect(102, 4, 8, 8, YELLOW)                    # nắng
    c.rect(101, 5, 10, 6, YELLOW)

    c.rect(26, 16, 78, 22, WHITE)                   # thân trường
    c.rect(24, 13, 82, 4, BLUE_MID)                 # mái
    c.rect(28, 12, 74, 2, BLUE)
    for row in range(2):                            # hai hàng cửa sổ
        for col in range(7):
            c.rect(31 + col * 10, 19 + row * 8, 6, 5, SKY_DEEP)
    c.rect(60, 28, 10, 10, BROWN)                   # cửa chính

    c.rect(64, 2, 1, 11, (120, 120, 120))           # cột cờ
    wave = (f // 3) % 3                             # cờ bay 3 nhịp
    for i in range(9):
        dy = (0, 1, 0, -1)[(i + wave) % 4]
        c.rect(65 + i, 3 + dy, 1, 6, RED)
    c.star(69, 6, YELLOW, size=1)

    walk = f * 2                                    # hai bạn đi vào trường
    for i, shirt in enumerate([RED, PURPLE]):
        bx = (8 + i * 14 + walk) % 130
        by = 40
        c.rect(bx + 2, by, 6, 5, SKIN)
        c.rect(bx + 1, by - 2, 8, 3, INK)
        c.rect(bx + 1, by + 5, 8, 7, shirt)
        step = 1 if (f + i) % 4 < 2 else 0
        c.rect(bx + 2, by + 12, 2, 3 - step, BLUE_MID)
        c.rect(bx + 6, by + 12, 2, 2 + step, BLUE_MID)
    return c.img


# ------------------------------------------------------ 47 · bút chì viết A+
def scene_pencil(f):
    c = Canvas(PAPER)
    for y in range(8, GH, 9):                       # dòng kẻ
        c.rect(0, y, GW, 1, RULE)
    c.rect(14, 0, 1, GH, (252, 165, 165))           # lề đỏ

    # Chữ A+ hiện dần theo nét bút: mỗi khung mở thêm một phần bề ngang.
    reveal = (1 + min(f, 8)) / 9
    glyph_x, glyph_y, scale = 20, 13, 4
    full_w = Canvas.text_w('A+', scale)
    shown = int(full_w * reveal)

    layer = Canvas(PAPER)
    for y in range(8, GH, 9):
        layer.rect(0, y, GW, 1, RULE)
    layer.rect(14, 0, 1, GH, (252, 165, 165))
    layer.text('A+', glyph_x, glyph_y, BLUE, scale=scale)
    box = layer.img.crop((glyph_x * CELL, glyph_y * CELL,
                          (glyph_x + shown) * CELL, (glyph_y + 7 * scale) * CELL))
    if shown > 0:
        c.img.paste(box, (glyph_x * CELL, glyph_y * CELL))

    # Bút chì bám theo mép nét đang viết.
    tip_x = glyph_x + shown
    tip_y = glyph_y + 7 * scale
    for i in range(11):                             # thân gỗ chéo 45 độ
        c.rect(tip_x + 2 + i, tip_y - 4 - i, 2, 2, AMBER)
    c.rect(tip_x, tip_y - 2, 3, 3, INK)             # đầu chì
    c.rect(tip_x + 13, tip_y - 16, 3, 3, PINK)      # cục tẩy

    if f >= 9:                                      # ăn mừng khi viết xong
        # Sao đổi cỡ theo khung: ba khung cuối mà đứng hình thì đoạn kết cụt
        # lủn, còn nhấp nháy thì mắt đọc ra là "xong rồi, giỏi lắm".
        pulse = (f - 9) % 3
        c.star(100, 22, YELLOW, size=3 + pulse)
        c.star(118, 38, AMBER, size=1 + (pulse + 1) % 3)
        c.star(88, 41, AMBER, size=1 + (pulse + 2) % 3)
        c.rect(96, 6, 26, 13, (187, 247, 208))
        c.text('10', 103, 9, GREEN_DARK, scale=1)
    return c.img


SCENES = {
    '38_chon_dap_an': scene_quiz,
    '42_diem_10': scene_great,
    '44_nhom_ban': scene_friends,
    '35_cong_truong': scene_school,
    '47_but_chi_a_cong': scene_pencil,
}


def save_gif(path, frames):
    """Ghi GIF, mọi khung dùng chung một bảng màu để không nhấp nháy."""
    master = frames[0].convert('P', palette=Image.Palette.ADAPTIVE, colors=64)
    conv = [fr.quantize(palette=master, dither=Image.Dither.NONE) for fr in frames]
    conv[0].save(path, save_all=True, append_images=conv[1:],
                 duration=DURATION, loop=0, optimize=True, disposal=2)


if __name__ == '__main__':
    import sys

    out_dir = sys.argv[1]
    for name, fn in SCENES.items():
        frames = [fn(f) for f in range(FRAMES)]
        path = f'{out_dir}/{name}.gif'
        save_gif(path, frames)
        size_kb = len(open(path, 'rb').read()) // 1024
        print(f'{name}.gif  {W}x{H}  {FRAMES} khung  {size_kb} KB')
