#include "gtest/gtest.h"



struct archived_tests : public testing::Test
{
	
};


#include <sstream>
#include <boost/spirit/include/qi.hpp>
namespace qi = boost::spirit::qi;


TEST_F(archived_tests, simple)
{
	using It      = std::string::const_iterator;
	using Skipper = qi::space_type;

	for (std::string const input : { R"_({{"1" , "2", "{5, 6, 8}"}, {"3", "4", "5"}})_" })
	{
		auto it = input.begin();

		using row  = std::vector<std::string>;
		using rows = std::vector<row>;

		qi::rule<It, std::string(), Skipper> string_ = qi::lexeme['"' >> +(qi::char_ - '"') >> '"'];
		qi::rule<It, row ()       , Skipper> row_    = "{" >> -(string_   % ",") >> "}";
		qi::rule<It, rows()       , Skipper> rows_   = "{" >> -(row_      % ",") >> "}";

		rows data;
		qi::phrase_parse(it, input.end(), rows_, qi::space, data);
		ASSERT_EQ(it, input.end());

		//print the result
		auto ss = std::stringstream();
		for (const auto& v : data) {
			ss << "[";
			for (auto i : v)
			{
				ss << i << ",";
			}
			ss << "],";
		}

		ASSERT_EQ(ss.str(), "[1,2,{5, 6, 8},],[3,4,5,],");
	}
}
