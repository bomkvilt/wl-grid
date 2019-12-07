#include <iostream>
#include <fstream>
#include <sstream>
#include "SQLiteCpp/SQLiteCpp.h"
#include "parser.hpp"



int main(int argc, char** argv)
{
	if (argc != 3)
	{
		std::cerr << "incorrect argument count: " << argc - 1 << std::endl;
		exit(1);
	}
	auto baseName = std::string(argv[1]) + ".db3";
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

	try
	{
		auto base = SQLite::Database(baseName, SQLite::OPEN_CREATE|SQLite::OPEN_READWRITE);
		base.exec("SELECT 5");
		auto _ = Parser::Parser(base)
			.LoadRequiredPoints(points)
			.SavePoints();
	}
	catch (const std::exception& e)
	{
		std::cerr << "unexpected exception: " << e.what() << std::endl;
		exit(1);
	}
}
