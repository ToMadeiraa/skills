# Structural Patterns

Patterns that explain how to assemble objects and classes into larger structures while keeping these structures flexible and efficient.

---

## Adapter

**Problem**: Incompatible interfaces prevent objects from working together (e.g., integrating a JSON-based library into an XML-based application).

**When to Use**:
- Need to use an existing class with an incompatible interface
- Want to reuse subclasses lacking common functionality
- Working with third-party libraries that don't match your interface

**Structure**:
- `Target` - Interface expected by client
- `Adapter` - Implements target, delegates to adaptee
- `Adaptee` - Existing class with incompatible interface
- `Client` - Works with target interface

**C++ Example**:
```
#include <iostream>
#include <memory>
#include <string>
#include <algorithm>

// Target interface — what new code expects
class IPrinter {
public:
    virtual ~IPrinter() = default;
    virtual void print(const std::string& text) const = 0;
};

// Adaptee — existing/legacy class with incompatible interface
class LegacyPrinter {
public:
    void printUppercase(const std::string& text) const {
        std::string s = text;
        std::transform(s.begin(), s.end(), s.begin(), ::toupper);
        std::cout << "[LEGACY] " << s << "\n";
    }
};

// Adapter — bridges the two
class PrinterAdapter : public IPrinter {
private:
    std::shared_ptr<LegacyPrinter> legacy_;
public:
    explicit PrinterAdapter(std::shared_ptr<LegacyPrinter> legacy)
        : legacy_(std::move(legacy)) {}

    void print(const std::string& text) const override {
        legacy_->printUppercase(text);
    }
};

// Client code — only knows IPrinter
void clientCode(const IPrinter& printer) {
    printer.print("hello world");
}

int main() {
    auto legacy = std::make_shared<LegacyPrinter>();
    PrinterAdapter adapter(legacy);

    clientCode(adapter);  // [LEGACY] HELLO WORLD
}
```

**Pros**:
- Single Responsibility - separates interface conversion from business logic
- Open/Closed - add new adapters without breaking existing code

**Cons**:
- Increases overall complexity
- Sometimes simpler to modify the service class directly

**Related**: Bridge (designed upfront vs. retrofitted), Decorator (changes interface), Facade (new simple interface)

---

## Decorator

**Problem**: Need to add behaviors to objects dynamically without creating an explosion of subclasses.

**When to Use**:
- Assign extra behaviors at runtime without breaking existing code
- Inheritance is impractical (e.g., `final` classes)
- Need to combine multiple behaviors flexibly

**Structure**:
- `Component` - Interface for objects
- `ConcreteComponent` - Basic implementation
- `Decorator` - Base class wrapping a component
- `ConcreteDecorator` - Adds specific behavior

**C++ Example**:
```
#include <iostream>
#include <memory>
#include <string>
#include <utility>

// Component interface
class Beverage {
public:
    virtual ~Beverage() = default;
    virtual std::string description() const = 0;
    virtual double cost() const = 0;
};

// Concrete component
class Espresso : public Beverage {
public:
    std::string description() const override { return "Espresso"; }
    double cost() const override { return 1.99; }
};

class HouseBlend : public Beverage {
public:
    std::string description() const override { return "House Blend"; }
    double cost() const override { return 0.89; }
};

// Base decorator — holds a wrapped component
class CondimentDecorator : public Beverage {
protected:
    std::unique_ptr<Beverage> inner_;
public:
    explicit CondimentDecorator(std::unique_ptr<Beverage> inner)
        : inner_(std::move(inner)) {}
};

// Concrete decorators
class Mocha : public CondimentDecorator {
public:
    using CondimentDecorator::CondimentDecorator;

    std::string description() const override {
        return inner_->description() + ", Mocha";
    }
    double cost() const override { return inner_->cost() + 0.20; }
};

class Whip : public CondimentDecorator {
public:
    using CondimentDecorator::CondimentDecorator;

    std::string description() const override {
        return inner_->description() + ", Whip";
    }
    double cost() const override { return inner_->cost() + 0.10; }
};

class Soy : public CondimentDecorator {
public:
    using CondimentDecorator::CondimentDecorator;

    std::string description() const override {
        return inner_->description() + ", Soy";
    }
    double cost() const override { return inner_->cost() + 0.15; }
};

int main() {
    // Double mocha + whip soy latte — built at runtime
    std::unique_ptr<Beverage> drink =
        std::make_unique<Whip>(
            std::make_unique<Mocha>(
                std::make_unique<Mocha>(
                    std::make_unique<Soy>(
                        std::make_unique<HouseBlend>()))));

    std::cout << drink->description() << "\n";  // House Blend, Soy, Mocha, Mocha, Whip
    std::cout << "$" << drink->cost() << "\n";  // $1.64
}
```

**Pros**:
- Extend behavior without new subclasses
- Add/remove responsibilities at runtime
- Combine multiple behaviors
- Single Responsibility - divide monolithic class

**Cons**:
- Hard to remove specific wrappers from stack
- Behavior depends on decorator order
- Initial configuration can be complex

**Related**: Adapter (changes interface), Proxy (different purpose), Composite (aggregates results)

---

## Facade

**Problem**: Working with complex subsystems requires extensive initialization, dependency tracking, and correct method execution order.

**When to Use**:
- Need a simple interface to a complex subsystem
- Subsystem is complex with many configuration details
- Want to layer a subsystem with entry points at each level

**Structure**:
- `Facade` - Provides simple interface to subsystem
- `Subsystem Classes` - Implement functionality, unaware of facade

**C++ Example**:
```
#include <iostream>
#include <string>

// ---- Subsystem classes (complex, independent) ----

class Amplifier {
public:
    void on()          { std::cout << "  Amplifier on\n"; }
    void off()         { std::cout << "  Amplifier off\n"; }
    void setVolume(int v) { std::cout << "  Volume = " << v << "\n"; }
};

class DvdPlayer {
public:
    void on()          { std::cout << "  DVD player on\n"; }
    void off()         { std::cout << "  DVD player off\n"; }
    void play(const std::string& movie) {
        std::cout << "  Playing \"" << movie << "\"\n";
    }
    void stop()        { std::cout << "  DVD stopped\n"; }
};

class Projector {
public:
    void on()          { std::cout << "  Projector on\n"; }
    void off()         { std::cout << "  Projector off\n"; }
    void wideScreenMode() { std::cout << "  Projector in widescreen\n"; }
};

class Lights {
public:
    void dim(int level) { std::cout << "  Lights dimmed to " << level << "%\n"; }
    void on()           { std::cout << "  Lights on\n"; }
};

class Screen {
public:
    void down() { std::cout << "  Screen down\n"; }
    void up()   { std::cout << "  Screen up\n"; }
};

// ---- Facade ----

class HomeTheaterFacade {
    Amplifier amp_;
    DvdPlayer dvd_;
    Projector projector_;
    Lights    lights_;
    Screen    screen_;
public:
    void watchMovie(const std::string& movie) {
        std::cout << "Get ready to watch a movie...\n";
        lights_.dim(10);
        screen_.down();
        projector_.on();
        projector_.wideScreenMode();
        amp_.on();
        amp_.setVolume(5);
        dvd_.on();
        dvd_.play(movie);
    }

    void endMovie() {
        std::cout << "Shutting movie theater down...\n";
        dvd_.stop();
        dvd_.off();
        amp_.off();
        projector_.off();
        screen_.up();
        lights_.on();
    }
};

// ---- Client ----

int main() {
    HomeTheaterFacade theater;
    theater.watchMovie("Inception");
    std::cout << "\n";
    theater.endMovie();
}
```

**Pros**:
- Isolates code from subsystem complexity
- Provides clean, simple interface

**Cons**:
- Can become a god object coupled to all classes

**Related**: Adapter (wraps single object), Abstract Factory (hides creation), Mediator (centralizes communication)

**Note**: Facade defines new interface; Adapter makes existing interfaces compatible.
