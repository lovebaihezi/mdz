# # What is MDZ? title id # 1 | \ ' x' g ][)(}{!@#$%^&

MDZ is a simple Markdown parser.

To parse Markdown into a middle represent, I use DFA.
Powered by Zig.

It can output XML, JSON and LaTex, which can also be configured.

## build from source

Please use Zig compiler master.

####NotTitle

##### title content begin with space
instant text

##### Valid Title

### title 1 test 2 3 4 56667 , > | 

####### Invalid Title

#######Invalid Title

## Unicode Sign

∮ E⋅da = Q,  n → ∞, ∑ f(i) = ∏ g(i), ∀x∈ℝ: ⌈x⌉ = −⌊−x⌋, α ∧ ¬β = ¬(¬α ∨ β),

ℕ ⊆ ℕ₀ ⊂ ℤ ⊂ ℚ ⊂ ℝ ⊂ ℂ, ⊥ < a ≠ b ≡ c ≤ d ≪ ⊤ ⇒ (A ⇔ B),

გთხოვთ ახლავე გაიაროთ რეგისტრაცია Unicode-ის მეათე საერთაშორისო
კონფერენციაზე დასასწრებად, რომელიც გაიმართება 10-12 მარტს,
ქ. მაინცში, გერმანიაში. კონფერენცია შეჰკრებს ერთად მსოფლიოს
ექსპერტებს ისეთ დარგებში როგორიცაა ინტერნეტი და Unicode-ი,
ინტერნაციონალიზაცია და ლოკალიზაცია, Unicode-ის გამოყენება
ოპერაციულ სისტემებსა, და გამოყენებით პროგრამებში, შრიფტებში,
ტექსტების დამუშავებასა და მრავალენოვან კომპიუტერულ სისტემებში.

## Code Block

inline code span: `echo 'hello world!'`, means echo `hello world!` in shell

code span with markdown span:

```Markdown
code Span syntax like: 
```c
#include <stdio.h>
int main() {
        printf("hello world!\n");
        return 0;
}
```

above is a simple example
```

