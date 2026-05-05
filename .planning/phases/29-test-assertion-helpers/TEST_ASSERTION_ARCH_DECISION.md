# Domain Data Capture for Testing Assertions in Mailglass

## Introduction
Capturing domain data (like a `%User{}` struct, or a `plan_id`) is essential for robust testing assertions. Rather than parsing HTML strings or inspecting recipient email addresses (`msg.to`), developers should be able to assert on the semantic domain objects passed into the mailable. For example, `assert_email_sent Welcome, user: user` is far less brittle and more meaningful than `assert_email_sent Welcome, to: "user@example.com"`.

This document evaluates three architectural options for capturing this data within Elixir/Mailglass, aiming for maximum developer ergonomics, minimal surprise, and alignment with the Elixir/Phoenix ecosystem.

---

## Option 1: Explicit `assign/3` Setters

**Example:**
```elixir
def welcome(user, plan) do
  new()
  |> to(user.email)
  |> assign(:user, user)
  |> assign(:plan, plan)
end
```

**Pros:**
- **Idiomatic Elixir:** Exactly mimics `Plug.Conn.assign/3` and `Phoenix.Socket.assign/3`. Elixir developers are already intimately familiar with this pattern.
- **Zero Magic:** The developer is in full control of what is exposed to the template and the testing environment.
- **No Restrictions:** Developers can pattern match, use guards, and define default arguments freely in their function heads.

**Cons/Footguns:**
- **Boilerplate and Brittleness:** If a developer only needs the user's email for the `to` field and doesn't use the `user` object in the template, they might forget to `assign(:user, user)`. Later, a test asserting `assert_email_sent Welcome, user: user` will fail confusingly because the domain object was never assigned to the struct, despite being passed to the function.

---

## Option 2: Single `assigns: %{}` Argument

**Example:**
```elixir
def welcome(%{user: user, plan: plan} = assigns) do
  new()
  |> assign(assigns)
  |> to(user.email)
end
```

**Pros:**
- **Enforced Consistency:** Maps perfectly to Phoenix LiveView's component boundaries (`update(assigns, socket)` or function components `def my_component(assigns)`).
- **Trivial Capture:** Because all arguments are inherently a single map, a framework wrapper or even the `new()` function could trivially capture the entire domain context.

**Cons/Footguns:**
- **Breaks Elixir Arity Idioms:** For standard API functions, Elixir developers strongly prefer positional arguments (e.g., `welcome(user)`). Forcing everything into a single map for a simple email constructor function feels overly heavy and un-idiomatic outside of UI component boundaries. It makes the API feel clunky.

---

## Option 3: `defmailable` Macro

**Example:**
```elixir
defmodule MyApp.Emails do
  use Mailglass.Mailable

  defmailable welcome(user, plan) do
    new()
    |> to(user.email)
  end
end
```
*(Under the hood, the macro intercepts the arguments and injects them into the `%Message{}` struct).*

**Pros:**
- **Developer Ergonomics (10/10):** No boilerplate whatsoever. The developer writes a normal function, and the testing framework automatically has access to the arguments (e.g., `args: [user, plan]`).
- **ActionMailer-like Testing:** Closely mimics Rails ActionMailer's ability to seamlessly assert on enqueued job arguments.

**Cons/Footguns:**
- **Extreme Macro Complexity:** Parsing Elixir function heads is notoriously difficult. Handling pattern matching (`defmailable welcome(%User{id: id} = user)`), guards (`when is_binary(id)`), default arguments (`plan \\ :free`), and multiple function clauses requires wrapping the implementation in a private function and generating a generic arity-matching public function. This is highly error-prone.
- **Principle of Least Surprise:** Fails this principle. Developers might not understand how the arguments magically end up in the test assertions. It breaks the mental model of "this is just a simple function that returns a struct". When magic breaks, it is very hard to debug.

---

## Lessons Learned from the Ecosystem

- **Rails ActionMailer:** Uses an orchestration object chain: `WelcomeMailer.with(user: user).welcome_email`. This separates domain data (`with`) from the delivery method. Testing `assert_enqueued_email_with` hooks into ActiveJob's serialization, naturally capturing the domain data. *Lesson: Framework-level orchestration makes assertions easy, but Elixir lacks a unified `with()` chaining object paradigm.*
- **Laravel Mailable:** Uses classes (`new WelcomeEmail($user)`). Public properties on the class are automatically made available to tests and templates. *Lesson: Object state makes this effortless, but Elixir structs require explicit transformation.*
- **Swoosh / Bamboo:** Both are explicit. You construct a struct and manually `assign` data if you want it in the struct. *Lesson: Explicit is idiomatic in Elixir, but can lead to boilerplate. Swoosh tests often devolve into fragile HTML string assertions because developers forget to assign domain data, limiting the utility of the test suite.*

---

## Cohesive Recommendation: The "Context-Aware" Explicit Pattern

Mailglass should adopt a hybrid approach that leans heavily on **Option 1 (Explicit `assign`)**, but with a highly ergonomic API inspired by Phoenix components and LiveView to minimize boilerplate.

### The Winning Architecture: Frictionless Assignment
**Do not** use a complex `defmailable` macro to parse function heads. **Do not** force a single `assigns` map argument. 

Instead, embrace standard Elixir functions, but make the assignment of domain data as frictionless as possible by allowing `new/1` to accept assigns directly:

```elixir
defmodule MyApp.WelcomeMailer do
  use Mailglass.Mailable
  # implicitly imports Message functions like assign/2 or assign/3

  def welcome(user, plan) do
    # 1. Frictionless assignment at instantiation
    new(user: user, plan: plan) 
    |> to(user.email)
    |> subject("Welcome to #{plan.name}")
  end
end
```

### Why this is the correct path for Mailglass:
1. **Zero Magic:** It's just functions and structs. Elixir LS, autocomplete, and Dialyzer will work perfectly. It completely avoids the brittleness of macro-based AST parsing.
2. **Idiomatic Phoenix:** `new(user: user)` feels remarkably similar to passing assigns to a LiveView component (`live_render(conn, View, session: %{"user" => user})`). It leverages keyword lists gracefully.
3. **Solves the Boilerplate Footgun:** By encouraging `new(user: user)` at the top of every mailable, the domain data is captured immediately upon struct creation (`%Message{assigns: %{user: user}}`). Developers won't forget to assign it later in the pipeline.
4. **Powerful, Semantic Assertions:** Test helpers can now easily and reliably assert against the assigns:
   ```elixir
   # Mailglass.Test
   assert_mail_sent WelcomeMailer, user: user
   # or
   assert_mail_sent(mailable_function: :welcome, assigns: %{user: user})
   ```

### Conclusion
By optimizing the ergonomics of explicit assignment (via `new(assigns)`), Mailglass elegantly avoids the immense complexity of function-head-parsing macros (Option 3) and the unnatural arity constraints of a forced map (Option 2), while solving the boilerplate complaints of strict setters (Option 1). This delivers a robust, idiomatic, and highly testable developer experience aligned perfectly with the Elixir/Phoenix ecosystem.