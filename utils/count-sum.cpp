#include <iostream>

using namespace std;

static unsigned long long int static_push, static_pop, dynamic_push, dynamic_pop;

int main() {
    static_pop = static_pop = dynamic_push = dynamic_pop = 0;

    std::string s;
    while (getline(cin, s)) {
        if (s[0] <= 1) continue;
        switch (s[0]) {
            case 'd': {
                if (s.substr(0, 20) == "dynamic push count: ") {
                    dynamic_push += stoll(s.substr(20));
                } 
                if (s.substr(0, 20) == "dynamic pop  count: ") {
                    dynamic_pop += stoll(s.substr(20));
                }
                break;
            }
            case 's': {
                if (s.substr(0, 20) == "static  push count: ") {
                    static_push += stoll(s.substr(20));
                } 
                if (s.substr(0, 20) == "static  pop  count: ") {
                    static_pop += stoll(s.substr(20));
                }
                break;
            }
        }
    }

    cout << "dynamic push: " << dynamic_push << endl;
    cout << "dynamic pop: " << dynamic_pop << endl;
    cout << "static push: " << static_push << endl;
    cout << "static pop: " << static_pop << endl;
    return 0;
}