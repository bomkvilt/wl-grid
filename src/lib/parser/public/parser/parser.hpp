#ifndef PARSER_PARSER_HPP
#define PARSER_PARSER_HPP

#include <vector>
#include <string>
#include <algorithm>
#include <boost/spirit/include/qi.hpp>
#include <boost/algorithm/string.hpp>

namespace qi = boost::spirit::qi;



class ParserBase
{
public:
	using ATable  = std::vector<std::vector<std::string>>;
public:
	
	ParserBase()
	{
		constexpr auto qt = '\'';
		string_ = qi::lexeme[qt >> +(qi::char_ - qt) >> qt];
		row_    = "{" >> -(string_ % ",") >> "}";
		rows_   = "{" >> -(row_    % ",") >> "}";
	}

	void ImportPoints(const std::string& data, ATable& imported)
	{
		auto pos = data.begin();
		auto end = data.end();
		auto res = Rows();

		qi::phrase_parse(pos, end, rows_, qi::space, res);
		if (pos != end)
		{
			throw std::runtime_error("unparsed part: " + std::string(pos, end));
		}
		
		for (auto& row : res)
		{
			imported.emplace_back(row.begin(), row.end());
		}
	}

	auto ExportPointChunks(const ATable& points, size_t size) const -> std::vector<std::string>
	{
		auto pos = points.begin();
		auto end = points.end();
		auto dist = std::distance(pos, end);

		auto chunks = std::vector<std::string>();

		auto max = std::ceil((0.f + dist) / size);
		for (size_t i = 0; i < max; ++i)
		{
			auto step = (i != max - 1) ? size : (dist - size * (max - 1));

			chunks.emplace_back(ExportPoints(
				pos + i * size, 
				pos + i * size + step
			));
		}
		return chunks;
	}

	std::string ExportPoints(const ATable& points) const
	{
		return ExportPoints(points.begin(), points.end());
	}

	std::string ExportPoints(ATable::const_iterator pos, ATable::const_iterator end) const
	{
		auto ss = std::stringstream();
		ss << "{";
		auto tmp = std::vector<std::string>();
		for (; pos != end; ++pos)
		{
			tmp.push_back("{" + boost::join(*pos, ",") + "}");
		}
		ss << boost::join(tmp, ",");
		ss << "}";
		return ss.str();
	}

private:
	using It      = std::string::const_iterator;
	using Skipper = qi::space_type;
	using Row     = std::vector<std::string>;
	using Rows    = std::vector<Row>;

	qi::rule<It, std::string(), Skipper> string_;
	qi::rule<It, Row(),  Skipper> row_;
	qi::rule<It, Rows(), Skipper> rows_;
};

#endif //!PARSER_PARSER_HPP
