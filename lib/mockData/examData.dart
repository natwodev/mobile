import '../models/DTOs/originalExamPaperDto.dart';

/// Mock data cho 30 câu hỏi trắc nghiệm với LaTeX phức tạp
class MockExamData {
  static List<OriginalExamPaperDetailDto> getMathQuestions() {
    return [
      // Câu 1: Tích phân cơ bản
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 1,
        order: 1,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent:
            r'''Tính tích phân: $$\int_0^{\pi} \sin^2(x) \, dx$$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 1,
            order: 1,
            answerContent: r'''$\frac{\pi}{2}$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 1,
          ),
          AnswerDto(
            answerId: 2,
            order: 2,
            answerContent: r'''$\pi$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 1,
          ),
          AnswerDto(
            answerId: 3,
            order: 3,
            answerContent: r'''$\frac{\pi}{4}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 1,
          ),
          AnswerDto(
            answerId: 4,
            order: 4,
            answerContent: r'''$2\pi$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 1,
          ),
        ],
      ),

      // Câu 2: Giới hạn với căn thức
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 2,
        order: 2,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent:
            r'''Tính giới hạn: $$\lim_{x \to 0} \frac{\sqrt{1+x} - \sqrt{1-x}}{x}$$''',
        correctAnswerIndex: 1,
        answers: [
          AnswerDto(
            answerId: 5,
            order: 1,
            answerContent: r'''$0$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 2,
          ),
          AnswerDto(
            answerId: 6,
            order: 2,
            answerContent: r'''$1$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 2,
          ),
          AnswerDto(
            answerId: 7,
            order: 3,
            answerContent: r'''$2$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 2,
          ),
          AnswerDto(
            answerId: 8,
            order: 4,
            answerContent: r'''$\frac{1}{2}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 2,
          ),
        ],
      ),

      // Câu 3: Ma trận và định thức
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 3,
        order: 3,
        chapterId: 2,
        canShuffleQuestion: false,
        questionContent:
            r'''Tính định thức của ma trận: $$A = \begin{pmatrix} 1 & 2 & 3 \\ 4 & 5 & 6 \\ 7 & 8 & 9 \end{pmatrix}$$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 9,
            order: 1,
            answerContent: r'''$0$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 3,
          ),
          AnswerDto(
            answerId: 10,
            order: 2,
            answerContent: r'''$-6$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 3,
          ),
          AnswerDto(
            answerId: 11,
            order: 3,
            answerContent: r'''$6$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 3,
          ),
          AnswerDto(
            answerId: 12,
            order: 4,
            answerContent: r'''$12$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 3,
          ),
        ],
      ),

      // Câu 4: Phương trình vi phân
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 4,
        order: 4,
        chapterId: 3,
        canShuffleQuestion: false,
        questionContent:
            r'''Nghiệm tổng quát của phương trình vi phân: $$\frac{dy}{dx} + 2y = e^{-x}$$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 13,
            order: 1,
            answerContent: r'''$y = e^{-x} + Ce^{-2x}$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 4,
          ),
          AnswerDto(
            answerId: 14,
            order: 2,
            answerContent: r'''$y = e^{-2x} + Ce^{-x}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 4,
          ),
          AnswerDto(
            answerId: 15,
            order: 3,
            answerContent: r'''$y = xe^{-x} + Ce^{-2x}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 4,
          ),
          AnswerDto(
            answerId: 16,
            order: 4,
            answerContent: r'''$y = (x+C)e^{-2x}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 4,
          ),
        ],
      ),

      // Câu 5: Chuỗi Taylor
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 5,
        order: 5,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent:
            r'''Khai triển Taylor của $e^x$ quanh $x=0$ là: $$e^x = \sum_{n=0}^{\infty} \frac{x^n}{n!}$$ 
Giá trị của $\sum_{n=0}^{\infty} \frac{1}{n!}$ là:''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 17,
            order: 1,
            answerContent: r'''$e$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 5,
          ),
          AnswerDto(
            answerId: 18,
            order: 2,
            answerContent: r'''$e^2$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 5,
          ),
          AnswerDto(
            answerId: 19,
            order: 3,
            answerContent: r'''$1$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 5,
          ),
          AnswerDto(
            answerId: 20,
            order: 4,
            answerContent: r'''$\pi$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 5,
          ),
        ],
      ),

      // Câu 6: Tích phân kép
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 6,
        order: 6,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent:
            r'''Tính tích phân kép: $$\iint_D xy \, dA$$ với $D = \{(x,y) : 0 \leq x \leq 1, 0 \leq y \leq 1\}$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 21,
            order: 1,
            answerContent: r'''$\frac{1}{4}$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 6,
          ),
          AnswerDto(
            answerId: 22,
            order: 2,
            answerContent: r'''$\frac{1}{2}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 6,
          ),
          AnswerDto(
            answerId: 23,
            order: 3,
            answerContent: r'''$1$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 6,
          ),
          AnswerDto(
            answerId: 24,
            order: 4,
            answerContent: r'''$\frac{1}{8}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 6,
          ),
        ],
      ),

      // Câu 7: Đạo hàm riêng
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 7,
        order: 7,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent:
            r'''Cho hàm số $f(x,y) = x^2 y + \sin(xy)$. Tính: $$\frac{\partial^2 f}{\partial x \partial y}$$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 25,
            order: 1,
            answerContent: r'''$2x + \cos(xy) - xy\sin(xy)$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 7,
          ),
          AnswerDto(
            answerId: 26,
            order: 2,
            answerContent: r'''$2x + \cos(xy)$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 7,
          ),
          AnswerDto(
            answerId: 27,
            order: 3,
            answerContent: r'''$x^2 + y\cos(xy)$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 7,
          ),
          AnswerDto(
            answerId: 28,
            order: 4,
            answerContent: r'''$2xy + \sin(xy)$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 7,
          ),
        ],
      ),

      // Câu 8: Số phức
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 8,
        order: 8,
        chapterId: 2,
        canShuffleQuestion: false,
        questionContent:
            r'''Cho số phức $z = 1 + i\sqrt{3}$. Tính $z^6$ sử dụng công thức De Moivre: $$z^n = r^n(\cos(n\theta) + i\sin(n\theta))$$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 29,
            order: 1,
            answerContent: r'''$64$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 8,
          ),
          AnswerDto(
            answerId: 30,
            order: 2,
            answerContent: r'''$-64$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 8,
          ),
          AnswerDto(
            answerId: 31,
            order: 3,
            answerContent: r'''$64i$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 8,
          ),
          AnswerDto(
            answerId: 32,
            order: 4,
            answerContent: r'''$-64i$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 8,
          ),
        ],
      ),

      // Câu 9: Tích vô hướng và tích có hướng
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 9,
        order: 9,
        chapterId: 2,
        canShuffleQuestion: false,
        questionContent:
            r'''Cho $\vec{a} = (1, 2, 3)$ và $\vec{b} = (4, 5, 6)$. Tính: $$\vec{a} \times \vec{b} = \begin{vmatrix} \vec{i} & \vec{j} & \vec{k} \\ 1 & 2 & 3 \\ 4 & 5 & 6 \end{vmatrix}$$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 33,
            order: 1,
            answerContent: r'''$(-3, 6, -3)$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 9,
          ),
          AnswerDto(
            answerId: 34,
            order: 2,
            answerContent: r'''$(3, -6, 3)$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 9,
          ),
          AnswerDto(
            answerId: 35,
            order: 3,
            answerContent: r'''$(3, 6, -3)$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 9,
          ),
          AnswerDto(
            answerId: 36,
            order: 4,
            answerContent: r'''$(-3, -6, -3)$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 9,
          ),
        ],
      ),

      // Câu 10: Phương trình lượng giác
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 10,
        order: 10,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent:
            r'''Giải phương trình: $$\sin^2(x) + \sin(x)\cos(x) - 2\cos^2(x) = 0$$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 37,
            order: 1,
            answerContent:
                r'''$x = \arctan(1) + k\pi$ hoặc $x = \arctan(-2) + k\pi$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 10,
          ),
          AnswerDto(
            answerId: 38,
            order: 2,
            answerContent: r'''$x = \frac{\pi}{4} + k\pi$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 10,
          ),
          AnswerDto(
            answerId: 39,
            order: 3,
            answerContent: r'''$x = \frac{\pi}{3} + k\pi$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 10,
          ),
          AnswerDto(
            answerId: 40,
            order: 4,
            answerContent: r'''$x = k\pi$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 10,
          ),
        ],
      ),

      // Câu 11: Tích phân đường
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 11,
        order: 11,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent:
            r'''Tính tích phân đường: $$\oint_C (x^2 + y^2) \, ds$$ với $C$ là đường tròn $x^2 + y^2 = R^2$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 41,
            order: 1,
            answerContent: r'''$2\pi R^3$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 11,
          ),
          AnswerDto(
            answerId: 42,
            order: 2,
            answerContent: r'''$\pi R^3$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 11,
          ),
          AnswerDto(
            answerId: 43,
            order: 3,
            answerContent: r'''$\pi R^2$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 11,
          ),
          AnswerDto(
            answerId: 44,
            order: 4,
            answerContent: r'''$2\pi R^2$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 11,
          ),
        ],
      ),

      // Câu 12: Biến đổi Laplace
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 12,
        order: 12,
        chapterId: 3,
        canShuffleQuestion: false,
        questionContent:
            r'''Tìm biến đổi Laplace của hàm $f(t) = t^2 e^{at}$: $$\mathcal{L}\{t^2 e^{at}\} = ?$$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 45,
            order: 1,
            answerContent: r'''$\frac{2}{(s-a)^3}$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 12,
          ),
          AnswerDto(
            answerId: 46,
            order: 2,
            answerContent: r'''$\frac{2}{(s+a)^3}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 12,
          ),
          AnswerDto(
            answerId: 47,
            order: 3,
            answerContent: r'''$\frac{1}{(s-a)^2}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 12,
          ),
          AnswerDto(
            answerId: 48,
            order: 4,
            answerContent: r'''$\frac{2!}{(s-a)^2}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 12,
          ),
        ],
      ),

      // Câu 13: Chuỗi Fourier
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 13,
        order: 13,
        chapterId: 3,
        canShuffleQuestion: false,
        questionContent:
            r'''Hệ số $a_0$ trong khai triển Fourier của hàm $f(x) = x$ trên $[-\pi, \pi]$: $$a_0 = \frac{1}{\pi} \int_{-\pi}^{\pi} f(x) \, dx$$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 49,
            order: 1,
            answerContent: r'''$0$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 13,
          ),
          AnswerDto(
            answerId: 50,
            order: 2,
            answerContent: r'''$\pi$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 13,
          ),
          AnswerDto(
            answerId: 51,
            order: 3,
            answerContent: r'''$2\pi$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 13,
          ),
          AnswerDto(
            answerId: 52,
            order: 4,
            answerContent: r'''$\frac{\pi}{2}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 13,
          ),
        ],
      ),

      // Câu 14: Gradient và Laplacian
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 14,
        order: 14,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent:
            r'''Cho $\phi(x,y,z) = x^2 + y^2 + z^2$. Tính Laplacian: $$\nabla^2 \phi = \frac{\partial^2 \phi}{\partial x^2} + \frac{\partial^2 \phi}{\partial y^2} + \frac{\partial^2 \phi}{\partial z^2}$$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 53,
            order: 1,
            answerContent: r'''$6$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 14,
          ),
          AnswerDto(
            answerId: 54,
            order: 2,
            answerContent: r'''$2$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 14,
          ),
          AnswerDto(
            answerId: 55,
            order: 3,
            answerContent: r'''$4$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 14,
          ),
          AnswerDto(
            answerId: 56,
            order: 4,
            answerContent: r'''$0$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 14,
          ),
        ],
      ),

      // Câu 15: Phương trình đặc trưng
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 15,
        order: 15,
        chapterId: 2,
        canShuffleQuestion: false,
        questionContent:
            r'''Tìm giá trị riêng của ma trận: $$A = \begin{pmatrix} 4 & 1 \\ 2 & 3 \end{pmatrix}$$ từ phương trình $\det(A - \lambda I) = 0$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 57,
            order: 1,
            answerContent: r'''$\lambda_1 = 5, \lambda_2 = 2$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 15,
          ),
          AnswerDto(
            answerId: 58,
            order: 2,
            answerContent: r'''$\lambda_1 = 4, \lambda_2 = 3$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 15,
          ),
          AnswerDto(
            answerId: 59,
            order: 3,
            answerContent: r'''$\lambda_1 = 6, \lambda_2 = 1$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 15,
          ),
          AnswerDto(
            answerId: 60,
            order: 4,
            answerContent: r'''$\lambda_1 = 7, \lambda_2 = 0$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 15,
          ),
        ],
      ),

      // Câu 16: Tổ hợp và xác suất
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 16,
        order: 16,
        chapterId: 4,
        canShuffleQuestion: false,
        questionContent:
            r'''Tính số cách chọn $k$ phần tử từ $n$ phần tử: $$\binom{n}{k} = \frac{n!}{k!(n-k)!}$$ Với $n = 10, k = 3$, kết quả là:''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 61,
            order: 1,
            answerContent: r'''$120$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 16,
          ),
          AnswerDto(
            answerId: 62,
            order: 2,
            answerContent: r'''$720$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 16,
          ),
          AnswerDto(
            answerId: 63,
            order: 3,
            answerContent: r'''$100$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 16,
          ),
          AnswerDto(
            answerId: 64,
            order: 4,
            answerContent: r'''$30$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 16,
          ),
        ],
      ),

      // Câu 17: Phương trình sóng
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 17,
        order: 17,
        chapterId: 3,
        canShuffleQuestion: false,
        questionContent:
            r'''Phương trình sóng một chiều: $$\frac{\partial^2 u}{\partial t^2} = c^2 \frac{\partial^2 u}{\partial x^2}$$ Nghiệm dạng D'Alembert là:''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 65,
            order: 1,
            answerContent: r'''$u(x,t) = f(x-ct) + g(x+ct)$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 17,
          ),
          AnswerDto(
            answerId: 66,
            order: 2,
            answerContent: r'''$u(x,t) = f(x)g(t)$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 17,
          ),
          AnswerDto(
            answerId: 67,
            order: 3,
            answerContent: r'''$u(x,t) = e^{-ct}\sin(x)$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 17,
          ),
          AnswerDto(
            answerId: 68,
            order: 4,
            answerContent: r'''$u(x,t) = \sin(x-ct)$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 17,
          ),
        ],
      ),

      // Câu 18: Công thức Euler
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 18,
        order: 18,
        chapterId: 2,
        canShuffleQuestion: false,
        questionContent:
            r'''Theo công thức Euler: $$e^{i\theta} = \cos(\theta) + i\sin(\theta)$$ Giá trị của $e^{i\pi} + 1$ là:''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 69,
            order: 1,
            answerContent: r'''$0$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 18,
          ),
          AnswerDto(
            answerId: 70,
            order: 2,
            answerContent: r'''$2$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 18,
          ),
          AnswerDto(
            answerId: 71,
            order: 3,
            answerContent: r'''$-2$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 18,
          ),
          AnswerDto(
            answerId: 72,
            order: 4,
            answerContent: r'''$i$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 18,
          ),
        ],
      ),

      // Câu 19: Tích phân bất định
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 19,
        order: 19,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent: r'''Tính: $$\int \frac{1}{x^2 + 4x + 5} \, dx$$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 73,
            order: 1,
            answerContent: r'''$\arctan(x+2) + C$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 19,
          ),
          AnswerDto(
            answerId: 74,
            order: 2,
            answerContent: r'''$\ln|x^2+4x+5| + C$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 19,
          ),
          AnswerDto(
            answerId: 75,
            order: 3,
            answerContent: r'''$\frac{1}{x+2} + C$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 19,
          ),
          AnswerDto(
            answerId: 76,
            order: 4,
            answerContent: r'''$\arcsin(x+2) + C$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 19,
          ),
        ],
      ),

      // Câu 20: Định lý Green
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 20,
        order: 20,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent:
            r'''Theo định lý Green: $$\oint_C (P\,dx + Q\,dy) = \iint_D \left(\frac{\partial Q}{\partial x} - \frac{\partial P}{\partial y}\right) dA$$ Với $P = y^2, Q = x^2$, biểu thức trong tích phân kép là:''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 77,
            order: 1,
            answerContent: r'''$2x - 2y$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 20,
          ),
          AnswerDto(
            answerId: 78,
            order: 2,
            answerContent: r'''$2x + 2y$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 20,
          ),
          AnswerDto(
            answerId: 79,
            order: 3,
            answerContent: r'''$x^2 - y^2$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 20,
          ),
          AnswerDto(
            answerId: 80,
            order: 4,
            answerContent: r'''$2xy$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 20,
          ),
        ],
      ),

      // Câu 21: Phân số tử số
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 21,
        order: 21,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent:
            r'''Phân tích thành phân số đơn giản: $$\frac{3x+5}{(x-1)(x+2)} = \frac{A}{x-1} + \frac{B}{x+2}$$ Giá trị của $A$ và $B$ là:''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 81,
            order: 1,
            answerContent: r'''$A = \frac{8}{3}, B = \frac{1}{3}$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 21,
          ),
          AnswerDto(
            answerId: 82,
            order: 2,
            answerContent: r'''$A = 2, B = 1$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 21,
          ),
          AnswerDto(
            answerId: 83,
            order: 3,
            answerContent: r'''$A = 3, B = 0$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 21,
          ),
          AnswerDto(
            answerId: 84,
            order: 4,
            answerContent: r'''$A = 1, B = 2$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 21,
          ),
        ],
      ),

      // Câu 22: Hàm Gamma
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 22,
        order: 22,
        chapterId: 3,
        canShuffleQuestion: false,
        questionContent:
            r'''Hàm Gamma định nghĩa: $$\Gamma(n) = \int_0^{\infty} t^{n-1}e^{-t}\,dt = (n-1)!$$ Giá trị của $\Gamma(5)$ là:''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 85,
            order: 1,
            answerContent: r'''$24$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 22,
          ),
          AnswerDto(
            answerId: 86,
            order: 2,
            answerContent: r'''$120$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 22,
          ),
          AnswerDto(
            answerId: 87,
            order: 3,
            answerContent: r'''$5$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 22,
          ),
          AnswerDto(
            answerId: 88,
            order: 4,
            answerContent: r'''$1$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 22,
          ),
        ],
      ),

      // Câu 23: Phương trình nhiệt
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 23,
        order: 23,
        chapterId: 3,
        canShuffleQuestion: false,
        questionContent:
            r'''Phương trình truyền nhiệt một chiều: $$\frac{\partial u}{\partial t} = \alpha \frac{\partial^2 u}{\partial x^2}$$ Đây là phương trình:''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 89,
            order: 1,
            answerContent: r'''Parabolic''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 23,
          ),
          AnswerDto(
            answerId: 90,
            order: 2,
            answerContent: r'''Elliptic''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 23,
          ),
          AnswerDto(
            answerId: 91,
            order: 3,
            answerContent: r'''Hyperbolic''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 23,
          ),
          AnswerDto(
            answerId: 92,
            order: 4,
            answerContent: r'''Linear''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 23,
          ),
        ],
      ),

      // Câu 24: Tích phân suy rộng
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 24,
        order: 24,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent:
            r'''Tích phân suy rộng: $$\int_0^{\infty} e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}$$ Từ đó, $\int_{-\infty}^{\infty} e^{-x^2}\,dx$ bằng:''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 93,
            order: 1,
            answerContent: r'''$\sqrt{\pi}$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 24,
          ),
          AnswerDto(
            answerId: 94,
            order: 2,
            answerContent: r'''$\pi$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 24,
          ),
          AnswerDto(
            answerId: 95,
            order: 3,
            answerContent: r'''$\frac{\sqrt{\pi}}{2}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 24,
          ),
          AnswerDto(
            answerId: 96,
            order: 4,
            answerContent: r'''$2\sqrt{\pi}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 24,
          ),
        ],
      ),

      // Câu 25: Định lý Stokes
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 25,
        order: 25,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent:
            r'''Định lý Stokes: $$\oint_C \vec{F} \cdot d\vec{r} = \iint_S (\nabla \times \vec{F}) \cdot d\vec{S}$$ Nếu $\vec{F} = (y, -x, z)$, thì $\nabla \times \vec{F}$ là:''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 97,
            order: 1,
            answerContent: r'''$(0, 0, -2)$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 25,
          ),
          AnswerDto(
            answerId: 98,
            order: 2,
            answerContent: r'''$(0, 0, 2)$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 25,
          ),
          AnswerDto(
            answerId: 99,
            order: 3,
            answerContent: r'''$(1, 1, 0)$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 25,
          ),
          AnswerDto(
            answerId: 100,
            order: 4,
            answerContent: r'''$(0, 1, -2)$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 25,
          ),
        ],
      ),

      // Câu 26: Phép biến đổi tuyến tính
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 26,
        order: 26,
        chapterId: 2,
        canShuffleQuestion: false,
        questionContent:
            r'''Ma trận của phép quay góc $\theta$ trong mặt phẳng: $$R(\theta) = \begin{pmatrix} \cos\theta & -\sin\theta \\ \sin\theta & \cos\theta \end{pmatrix}$$ Với $\theta = \frac{\pi}{2}$, ma trận là:''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 101,
            order: 1,
            answerContent:
                r'''$\begin{pmatrix} 0 & -1 \\ 1 & 0 \end{pmatrix}$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 26,
          ),
          AnswerDto(
            answerId: 102,
            order: 2,
            answerContent:
                r'''$\begin{pmatrix} 0 & 1 \\ -1 & 0 \end{pmatrix}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 26,
          ),
          AnswerDto(
            answerId: 103,
            order: 3,
            answerContent:
                r'''$\begin{pmatrix} 1 & 0 \\ 0 & 1 \end{pmatrix}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 26,
          ),
          AnswerDto(
            answerId: 104,
            order: 4,
            answerContent:
                r'''$\begin{pmatrix} -1 & 0 \\ 0 & -1 \end{pmatrix}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 26,
          ),
        ],
      ),

      // Câu 27: Chuỗi lũy thừa
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 27,
        order: 27,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent:
            r'''Bán kính hội tụ của chuỗi: $$\sum_{n=1}^{\infty} \frac{n!}{n^n} x^n$$ được tính bằng công thức: $$R = \lim_{n \to \infty} \left|\frac{a_n}{a_{n+1}}\right|$$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 105,
            order: 1,
            answerContent: r'''$R = e$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 27,
          ),
          AnswerDto(
            answerId: 106,
            order: 2,
            answerContent: r'''$R = 1$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 27,
          ),
          AnswerDto(
            answerId: 107,
            order: 3,
            answerContent: r'''$R = \infty$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 27,
          ),
          AnswerDto(
            answerId: 108,
            order: 4,
            answerContent: r'''$R = 0$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 27,
          ),
        ],
      ),

      // Câu 28: Phương trình Schrödinger
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 28,
        order: 28,
        chapterId: 4,
        canShuffleQuestion: false,
        questionContent:
            r'''Phương trình Schrödinger không phụ thuộc thời gian: $$-\frac{\hbar^2}{2m}\frac{d^2\psi}{dx^2} + V(x)\psi = E\psi$$ Với hố thế vô hạn, năng lượng: $$E_n = \frac{n^2\pi^2\hbar^2}{2mL^2}$$ Tỉ lệ $E_2/E_1$ là:''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 109,
            order: 1,
            answerContent: r'''$4$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 28,
          ),
          AnswerDto(
            answerId: 110,
            order: 2,
            answerContent: r'''$2$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 28,
          ),
          AnswerDto(
            answerId: 111,
            order: 3,
            answerContent: r'''$\sqrt{2}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 28,
          ),
          AnswerDto(
            answerId: 112,
            order: 4,
            answerContent: r'''$8$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 28,
          ),
        ],
      ),

      // Câu 29: Đạo hàm logarithm
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 29,
        order: 29,
        chapterId: 1,
        canShuffleQuestion: false,
        questionContent:
            r'''Tính đạo hàm: $$\frac{d}{dx}\left[x^x\right] = \frac{d}{dx}\left[e^{x\ln x}\right]$$''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 113,
            order: 1,
            answerContent: r'''$x^x(\ln x + 1)$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 29,
          ),
          AnswerDto(
            answerId: 114,
            order: 2,
            answerContent: r'''$x^{x-1}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 29,
          ),
          AnswerDto(
            answerId: 115,
            order: 3,
            answerContent: r'''$x^x \ln x$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 29,
          ),
          AnswerDto(
            answerId: 116,
            order: 4,
            answerContent: r'''$x \cdot x^{x-1}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 29,
          ),
        ],
      ),

      // Câu 30: Tích phân beta
      OriginalExamPaperDetailDto(
        originalExamPaperDetailId: 30,
        order: 30,
        chapterId: 3,
        canShuffleQuestion: false,
        questionContent:
            r'''Hàm Beta định nghĩa: $$B(m,n) = \int_0^1 x^{m-1}(1-x)^{n-1}\,dx = \frac{\Gamma(m)\Gamma(n)}{\Gamma(m+n)}$$ Giá trị $B(2,3)$ là:''',
        correctAnswerIndex: 0,
        answers: [
          AnswerDto(
            answerId: 117,
            order: 1,
            answerContent: r'''$\frac{1}{12}$''',
            isCorrect: true,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 30,
          ),
          AnswerDto(
            answerId: 118,
            order: 2,
            answerContent: r'''$\frac{1}{6}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 30,
          ),
          AnswerDto(
            answerId: 119,
            order: 3,
            answerContent: r'''$\frac{1}{4}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 30,
          ),
          AnswerDto(
            answerId: 120,
            order: 4,
            answerContent: r'''$\frac{1}{2}$''',
            isCorrect: false,
            canShuffleAnswer: false,
            originalExamPaperDetailId: 30,
          ),
        ],
      ),
    ];
  }
}
