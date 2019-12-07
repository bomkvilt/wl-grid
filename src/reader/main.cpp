#include <iostream>
#include <sstream>
#include <fstream>
#include <filesystem>
#include "SQLiteCpp/SQLiteCpp.h"
#include "parser.hpp"



int main(int argc, char** argv)
{
	if (argc != 3)
	{
		std::cerr << "incorrect argument count: " << argc - 1 << std::endl;
		exit(1);
	}
	auto baseName  = std::string(argv[1]) + ".db3";
	auto pointFile = std::string(argv[2]);

	auto is = std::ifstream(pointFile);
	if (!is)
	{
		std::cerr << "cannot open file: " << pointFile << std::endl;
		exit(1);
	}
	auto points = std::string(
		std::istreambuf_iterator<char>(is),
		std::istreambuf_iterator<char>()
	);
	is.close();
	
	if (!std::filesystem::exists(baseName))
	{
		std::cout << Parser::GetEmptyResult(points) << std::endl;
		exit(0);
	}

	try
	{
		auto base = SQLite::Database(baseName, SQLite::OPEN_READONLY);
		auto result = Parser::Parser(base)
			.LoadRequiredPoints(points)
			.FindPoints()
			.GetResults();
		std::cout << result;
	}
	catch (const std::exception& e)
	{
		std::cerr << "unexpected exception: " << e.what() << std::endl;
		exit(1);
	}
}
