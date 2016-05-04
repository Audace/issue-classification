import os
import csv
import time
import openpyxl
from github import Github

dir_path = os.path.dirname(os.path.realpath(__file__))
g = Github("username","access-token")

def search_repos():
    search_results = g.search_repositories('python+language:python', sort='stars', order='desc')
    repos = []
    with open('repos.csv', 'w') as csvfile:
        fieldnames = ['id', 'url', 'name', 'desc', 'lang', 'open_issues_count',
                      'stars', 'watching', 'forked', 'owner_un', 'owner_id']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()

        for repo in search_results:
            repo_data = { "id": repo.id, "url": repo.url, "name": repo.full_name, "desc": repo.description.encode('ascii', 'ignore'), "lang": repo.language, "open_issues_count": repo.open_issues_count, "stars": repo.stargazers_count, "watching": repo.watchers_count, "forked": repo.forks_count, "owner_un": repo.owner.login, "owner_id": repo.owner.id }
            writer.writerow(repo_data)
            repos.append(repo_data)
    return repos


def search_issues(repos=None):
    with open('repos.csv') as csvfile:
        reader = csv.DictReader(csvfile)
        with open('issues.csv', 'w') as issuesfile:
            workbook = openpyxl.load_workbook(dir_path + '/issues.xlsx')
            sheet = workbook.get_sheet_by_name('Sheet1')
            for repo in reader:
                q = 'repo:' + repo['name'] + ' state:closed type:issue'
                search_results = g.search_issues(q)

                for issue in search_results:
                    if g.rate_limiting[0] == 5:
                        time.sleep(1)
                    labels = [label.name.encode('ascii','ignore') for label in issue.labels]
                    if labels == []:
                        continue

                    title = ''
                    body = ''
                    if issue.title != None:
                        title = issue.title.encode('ascii', 'ignore')
                    if issue.body != None:
                        body = issue.body.encode('ascii', 'ignore')
                    issue_data = [issue.id, title, body, issue.number, issue.comments, repo["id"]] + labels
                    for col_index, cell in enumerate(issue_data):
                        try:
                            sheet.cell(row=(issues_stored+1),column=(col_index+1),value=cell)
                        except:
                            pass
                    workbook.save(dir_path + '/issues.xlsx')
