#ifndef READER_PARSER_HPP
#define READER_PARSER_HPP

#include <map>
#include <string_view>

#include <boost/algorithm/string.hpp>

#include "SQLiteCpp/SQLiteCpp.h"
#include "reflect/reflect.hpp"
#include "parser/parser.hpp"



class Parser : public ParserBase
{
public:
	Parser(SQLite::Database& db): base(&db)
	{}

	Parser(): base(nullptr)
	{}

	Parser& LoadRequiredPoints(const std::string& data)
	{
		ImportPoints(data, rpoints);
		return *this;
	}

	Parser& FindPoints()
	{
		if (!base)
		{
			return *this;
		}

		auto query = SQLite::Statement(*base, "SELECT * FROM points WHERE coordinates == ?");
		for (auto point : rpoints)
		{
			query.bind(1, boost::join(point, "___"));
			if (query.executeStep())
			{
				std::string payload = query.getColumn(2);
				point.push_back(payload);
				lpoints.emplace_back(std::move(point));
			}
			else
			{
				mpoints.emplace_back(std::move(point));
			}
			query.reset();
		}
		return *this;
	}

	auto GetResults() -> std::tuple<std::vector<std::string>, std::vector<std::string>>
	{
		auto missing = ExportPointChunks(mpoints, 20000);
		auto found   = ExportPointChunks(lpoints, 20000);
		return { found, missing };
	}

	auto GetEmptyResult() -> std::tuple<std::vector<std::string>, std::vector<std::string>>
	{
		auto missing = ExportPointChunks(rpoints , 20000);
		auto found   = ExportPointChunks(ATable(), 20000);
		return { found, missing };
	}

private:
	SQLite::Database* base;

	ATable rpoints; // required points
	ATable mpoints; // missings points
	ATable lpoints; // loaded points
};


#endif //!READER_PARSER_HPP
