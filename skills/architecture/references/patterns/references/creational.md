# Creational Patterns

Patterns that handle object creation mechanisms, increasing flexibility and reuse of existing code.

---

## Factory Method

**Problem**: Creating objects without specifying exact classes causes tight coupling between creator and concrete types.

**When to Use**:
- You don't know exact types beforehand
- You want to provide extension points for library users
- You need to reuse existing objects instead of rebuilding them

**Structure**:
- `Creator` - Declares factory method
- `ConcreteCreator` - Overrides factory method
- `Product` - Interface for objects
- `ConcreteProduct` - Implements product interface

**C++ Example**:
```
#include <iostream>
#include <memory>
#include <string>
#include <unordered_map>
#include <functional>

// Base product
class Shape {
public:
    virtual ~Shape() = default;
    virtual void draw() const = 0;
    virtual std::string name() const = 0;
};

// Concrete products
class Circle : public Shape {
public:
    void draw() const override { std::cout << "Drawing Circle\n"; }
    std::string name() const override { return "Circle"; }
};

class Square : public Shape {
public:
    void draw() const override { std::cout << "Drawing Square\n"; }
    std::string name() const override { return "Square"; }
};

class Triangle : public Shape {
public:
    void draw() const override { std::cout << "Drawing Triangle\n"; }
    std::string name() const override { return "Triangle"; }
};

// Generic factory
template <typename T>
class Factory {
public:
    using Creator = std::function<std::unique_ptr<T>()>;
    
    void registerType(const std::string& key, Creator creator) {
        creators_[key] = std::move(creator);
    }
    
    std::unique_ptr<T> create(const std::string& key) const {
        auto it = creators_.find(key);
        if (it == creators_.end())
            return nullptr;
        return it->second();
    }
    
private:
    std::unordered_map<std::string, Creator> creators_;
};

int main() {
    Factory<Shape> factory;
    factory.registerType("circle",   [] { return std::make_unique<Circle>(); });
    factory.registerType("square",   [] { return std::make_unique<Square>(); });
    factory.registerType("triangle", [] { return std::make_unique<Triangle>(); });
    
    for (const auto& key : {"circle", "square", "triangle", "hexagon"}) {
        if (auto shape = factory.create(key)) {
            std::cout << shape->name() << ": ";
            shape->draw();
        } else {
            std::cout << "Unknown shape: " << key << "\n";
        }
    }
}
```

**Pros**:
- Avoids coupling between creator and products
- Single Responsibility - centralized creation code
- Open/Closed - add new products without breaking existing code

**Cons**:
- Can require many subclasses

**Related**: Often evolves to Abstract Factory, Prototype, or Builder

---

## Abstract Factory

**Problem**: Need to create families of related objects while ensuring compatibility without depending on concrete classes.

**When to Use**:
- Code needs to work with various families of related products
- You can't predict product variants beforehand
- A class has multiple factory methods obscuring its main responsibility

**Structure**:
- `AbstractFactory` - Interface for creating product families
- `ConcreteFactory` - Implements creation methods for variants
- `AbstractProduct` - Interfaces for each product type
- `ConcreteProduct` - Implementations for each variant

**C++ Example**:
```
#include <iostream>
#include <memory>
#include <string>

// ---------- Abstract Products ----------
struct Button {
    virtual ~Button() = default;
    virtual void paint() const = 0;
};

struct Checkbox {
    virtual ~Checkbox() = default;
    virtual void paint() const = 0;
};

// ---------- Abstract Factory ----------
struct GUIFactory {
    virtual ~GUIFactory() = default;
    virtual std::unique_ptr<Button>   createButton()   const = 0;
    virtual std::unique_ptr<Checkbox> createCheckbox() const = 0;
};

// ---------- Concrete Family 1: Windows ----------
struct WinButton : Button {
    void paint() const override { std::cout << "[Win] Button\n"; }
};
struct WinCheckbox : Checkbox {
    void paint() const override { std::cout << "[Win] Checkbox\n"; }
};

struct WinFactory : GUIFactory {
    std::unique_ptr<Button>   createButton()   const override { return std::make_unique<WinButton>(); }
    std::unique_ptr<Checkbox> createCheckbox() const override { return std::make_unique<WinCheckbox>(); }
};

// ---------- Concrete Family 2: macOS ----------
struct MacButton : Button {
    void paint() const override { std::cout << "[Mac] Button\n"; }
};
struct MacCheckbox : Checkbox {
    void paint() const override { std::cout << "[Mac] Checkbox\n"; }
};

struct MacFactory : GUIFactory {
    std::unique_ptr<Button>   createButton()   const override { return std::make_unique<MacButton>(); }
    std::unique_ptr<Checkbox> createCheckbox() const override { return std::make_unique<MacCheckbox>(); }
};

// ---------- Client ----------
void renderUI(const GUIFactory& f) {
    auto b = f.createButton();
    auto c = f.createCheckbox();
    b->paint();
    c->paint();
}

int main() {
    WinFactory win;
    MacFactory mac;
    renderUI(win);
    renderUI(mac);
}
```

**Pros**:
- Ensures product compatibility
- Avoids tight coupling to concrete products
- Single Responsibility - centralized product creation
- Open/Closed - new variants without breaking existing code

**Cons**:
- Significant complexity with many new interfaces/classes

**Related**: Often evolves from Factory Method; can be implemented with Prototype or Builder

---

## Builder

**Problem**: Constructing complex objects with many optional parameters leads to giant constructors or subclass explosion.

**When to Use**:
- Telescoping constructors with many optional parameters
- Need to create different representations of a product
- Constructing complex composite objects like trees

**Structure**:
- `Builder` - Interface for construction steps
- `ConcreteBuilder` - Implements steps for specific representation
- `Director` - Defines construction order (optional)
- `Product` - Complex object being built

**C++ Example**:
```
#include <iostream>
#include <string>
#include <vector>

// ---------- Product ----------
struct Pizza {
    std::string size;
    std::string crust;
    std::vector<std::string> toppings;
    bool cheese = false;

    void describe() const {
        std::cout << "Pizza [" << size << ", " << crust << "] cheese=" << cheese << " toppings:";
        for (auto& t : toppings) std::cout << ' ' << t;
        std::cout << '\n';
    }
};

// ---------- Builder ----------
template <typename T>
class Builder {
public:
    T& self() { return static_cast<T&>(*this); }

    template <typename... Args>
    auto& with(Args&&... args) {
        self().build(std::forward<Args>(args)...);
        return self();
    }

    Pizza build() { return std::move(self().result_); }

protected:
    Pizza result_;
};

class MargheritaBuilder : public Builder<MargheritaBuilder> {
    friend class Builder<MargheritaBuilder>;
    void build(std::string size)         { result_.size = std::move(size); }
    void build(std::string crust, bool c){ result_.crust = std::move(crust); result_.cheese = c; }
    void build(std::vector<std::string> t) { result_.toppings = std::move(t); }
};

int main() {
    auto pizza = MargheritaBuilder{}
        .with("large")
        .with("thin", true)
        .with(std::vector<std::string>{"basil", "tomato"})
        .build();
    pizza.describe();
}
```

**Pros**:
- Construct objects step-by-step
- Reuse construction code for different representations
- Single Responsibility - isolates complex construction

**Cons**:
- Increases code complexity with new classes

**Related**: Can combine with Composite for tree construction; often implemented alongside other creational patterns

---

## Singleton

**Problem**: Need to ensure a class has only one instance with global access point.

**When to Use**:
- Single shared resource (database, file) needs controlled access
- Need stricter control than global variables
- ⚠️ **Use sparingly** - often indicates design issues

**Structure**:
- Single class with private constructor and static instance field
- Static method to get instance (lazy initialization)

**C++ Example**:
```
#include <iostream>

class Config {
public:
    static Config& instance() {
        static Config inst;   // thread-safe, lazy, destroyed at program exit
        return inst;
    }

    void set(const std::string& k, const std::string& v) { data_[k] = v; }
    std::string get(const std::string& k) const {
        auto it = data_.find(k);
        return it != data_.end() ? it->second : "";
    }

    // Delete copy/move to enforce uniqueness
    Config(const Config&)            = delete;
    Config& operator=(const Config&) = delete;
    Config(Config&&)                 = delete;
    Config& operator=(Config&&)      = delete;

private:
    Config() = default;   // private constructor
    std::unordered_map<std::string, std::string> data_;
};

int main() {
    Config::instance().set("theme", "dark");
    std::cout << Config::instance().get("theme") << '\n';
}
```

**Pros**:
- Guarantees single instance
- Global access point
- Lazy initialization

**Cons**:
- Violates Single Responsibility Principle
- Can mask poor design
- Difficult to test (private constructor)
- Thread safety concerns in multi-threaded environments
- **Better alternative**: Use dependency injection

**Related**: Facade can become Singleton; many patterns can be implemented as Singletons

**⚠️ Warning**: Overuse of Singleton is an anti-pattern. Consider dependency injection instead.
