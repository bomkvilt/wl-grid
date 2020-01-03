#include <iostream>
#include <sstream>
#include <fstream>
#include <filesystem>
#include <chrono>
#include "SQLiteCpp/SQLiteCpp.h"
#include "parser.hpp"


std::string SaveToFile(const std::string& baseName, const std::string& data)
{
	auto name = baseName + "." + std::to_string(std::rand());
	if (auto of = std::ofstream(name)) 
	{
		of << data;
	} 
	else
	{
		throw std::runtime_error("cannot open file: " + name);
	}
	return name;
}

std::vector<std::string> SaveToFiles(const std::string& baseName, const std::vector<std::string>& chunks)
{
	auto files = std::vector<std::string>();
	for (auto& chunk : chunks)
	{
		files.emplace_back('"' + SaveToFile(baseName, chunk) + '"');
	}
	return files;
}

std::string GenerateOutput(const std::vector<std::string>& files_found, const std::vector<std::string>& files_missing)
{
	return "<| \"found\" -> {" + boost::join(files_found  , ",") + "}, "
		+   "\"missing\" -> {" + boost::join(files_missing, ",") + "} |>";
}


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
		auto [found, missing] = Parser::Parser()
			.LoadRequiredPoints(points)
			.GetEmptyResult();
		auto files_found   = SaveToFiles(baseName, found  );
		auto files_missing = SaveToFiles(baseName, missing);
		std::cout << GenerateOutput(files_found, files_missing) << std::endl;
		exit(0);
	}

	try
	{
		auto base = SQLite::Database(baseName, SQLite::OPEN_READONLY);
		auto [found, missing] = Parser::Parser(base)
			.LoadRequiredPoints(points)
			.FindPoints()
			.GetResults();
		auto files_found   = SaveToFiles(baseName, found  );
		auto files_missing = SaveToFiles(baseName, missing);
		std::cout << GenerateOutput(files_found, files_missing) << std::endl;
	}
	catch (const std::exception& e)
	{
		std::cerr << "unexpected exception: " << e.what() << std::endl;
		exit(1);
	}
}
