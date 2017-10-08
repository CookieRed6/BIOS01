#include <intrin.h>

#include <SDL2/SDL.h>
#include <iostream>

#include <globals.hpp>

#include <neko.hpp>
#include <api.hpp>

#undef main

int main(int argc, char *argv[]) {
	// Parse args
	for (int i = 1; i < argc; i++) {
		std::cout << argv[i] << "\n";

		if (strcmp(argv[i], (strlen(argv[i]) > 2 ? "--help" : "-h")) == 0) {
			std::cout << "Help" << "\n";
			return 0;
		} else if (strcmp(argv[i], (strlen(argv[i]) > 2 ? "--debug" : "-d")) == 0) {
			globals::debug = 1;
			std::cout << "debug" << "\n";
		} else if (strcmp(argv[i], (strlen(argv[i]) > 2 ? "--loadcart" : "-l")) == 0) {
			//if (argv[i+1] && argv[i+1]) {

			//}
		}
	}

	// Set random seed based on system time
	srand(time(NULL));

	// Init SDL video system
	SDL_Init(SDL_INIT_VIDEO);

	// Open config

	neko_config config;

	// Init neko8
	neko *machine = machine::init(&config);

	// Used to get info about events
	SDL_Event event;
	// If true, neko8 should draw next frame
	bool running = true;

	std::cout << "Running with DEBUG mode " << ((globals::debug) ? "ON" : "OFF") << "\n";

	while (running) {
		while (SDL_PollEvent(&event)) {
			// We got some kind-of an event
			switch (event.type) {
				case SDL_QUIT:
					// User closes the window
					running = false;
					// TODO: save here
					break;
				default:
					// Something else, that we don't care about
					break;
			}
		}

		api::flip(machine);
	}

	// Free neko
	machine::free(machine);
	// And exit
	SDL_Quit();

	return 0;
}
