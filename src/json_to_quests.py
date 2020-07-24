#!/usr/bin/env python3

import sys
import json


def main():
    if len(sys.argv) != 3:
        print("Usage: {} <template_file> <output_file>".format(sys.argv[0]))
        sys.exit(1)

    try:
        quest_json_file = open(sys.argv[1], "r")
    except IOError:
        print("File '{}' doesn't exist".format(sys.argv[1]))
        sys.exit(1)

    try:
        quests_obj = json.load(quest_json_file)
    except ValueError as err:
        print("Error while parsing json: {}".format(str(err)))
        sys.exit(1)

    quest_json_file.close()

    quests_list = quests_obj.get("questions")
    if quests_list is None:
        print("Questions JSON haven't 'questions' array")
        sys.exit(1)

    output_file = open(sys.argv[2], "w")

    quest_number = 1
    try:
        for question in quests_list:
            output_file.write("Template: {}\n".format(question["template"]))
            output_file.write("Type: {}\n".format(question["type"]))
            output_file.write("Description: {}\n".format(question["question"]))
            output_file.write(" {}\n".format(question["description"]))
            if question.get("default") is not None:
                output_file.write("Default: {}\n".format(question["default"]))
            output_file.write("\n")

            quest_number += 1
    except KeyError as err:
        print("Key {} missed in {} question".format(str(err), quest_number))
        output_file.truncate(0)
        output_file.close()

        sys.exit(1)

    output_file.close()


main()
sys.exit(0)
