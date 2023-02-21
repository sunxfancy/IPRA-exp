#include <iostream>

using namespace std;

static unsigned long long int static_push, static_pop, dynamic_push, dynamic_pop;
static unsigned long long int static_spill, static_reload, dynamic_spill, dynamic_reload;

int main() {
    static_push = static_pop = dynamic_push = dynamic_pop = 0;
    static_spill = static_reload = dynamic_spill = dynamic_reload = 0;

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
                if (s.substr(0, 20) == "dynamic spill  (B): ") {
                    dynamic_spill += stoll(s.substr(20));
                }
                if (s.substr(0, 20) == "dynamic reload (B): ") {
                    dynamic_reload += stoll(s.substr(20));
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
                if (s.substr(0, 20) == "static  spill  (B): ") {
                    static_spill += stoll(s.substr(20));
                }
                if (s.substr(0, 20) == "static  reload (B): ") {
                    static_reload += stoll(s.substr(20));
                }
                break;
            }
        }
    }

    if (dynamic_push) cout << "dynamic push: " << dynamic_push << endl;
    if (dynamic_pop) cout << "dynamic pop: " << dynamic_pop << endl;
    if (static_push) cout << "static push: " << static_push << endl;
    if (static_pop) cout << "static pop: " << static_pop << endl;
    if (dynamic_spill) cout << "dynamic spill: " << dynamic_spill << endl;
    if (dynamic_reload) cout << "dynamic reload: " << dynamic_reload << endl;
    if (static_spill) cout << "static spill: " << static_spill << endl;
    if (static_reload) cout << "static reload: " << static_reload << endl;
    return 0;
}