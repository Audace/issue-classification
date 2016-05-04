=================================================================
Classification of Github Repository Issues: Reducing the Noise for Maintainers of Open-Source Python Projects
=================================================================

This repository makes up my final project for Statistics 471: Modern Data Mining.

# Introduction #
Software and the Internet it supports are largely products of open-source projects. From languages such as Java and Python to software such as Apache Hadoop and Linux, open-source projects ensure that the source code is maintained at the highest quality, while allowing anyone to leverage the
software to make the world a better place. Many of the top open-source projects are hosted on Github, a repository hosting service. Github allows anyone to upload software projects, helping them manage the different versions and revisions. Fittingly, Github is the primary hosting service among open-source projects. Among its most popular features, Github allows users to submit issues to projects. Users often do this when they have a question, find an error within the code, or have a feature they would like to request. Those who help fix and improve the open-source projects are often referred to as the project’s maintainers or collaborators.

As some open-source projects on Github have as many as 20,000 users following their activity, it becomes quite a job in-and-of-itself just to prioritize and assign the issues to collaborators. As the popularity of an open- source project rises, it becomes increasingly important to fix ‘critical’ bugs right away as many developers and businesses rely on the source code for day-to-day operations. The collaborators of a project will often use labels to triage issues. In an attempt to allow open- source project maintainers to focus on the important submitted issues, I have developed a model in R using text mining and logistic regression methods to classify an issue as ‘critical’ or not (or rather to apply a label of ‘critical’). To simplify this undertaking, this paper focuses only on projects written largely in Python.

The following project will examine the data collection and cleaning process as well as the various methods used. The results will be presented and critiqued. Lastly, opportunity for further statistical work will be presented.

# Overview #
The official write up is included as PDF. The Python script was used to pull the data from Github. The two csvs hold the data for the repos and their corresponding issues. Lastly all the statistics referenced in the paper come from the code in the R script.

The project needs a lot of work. This was very much a demo to see if the hypothesis of classifying issues had any hope to be valid. Judging by the results, something can be done here. However, the MSE needs to be significantly lower for this to be productized and open-sourced. I'll be exploring this over the summer.

Let me know if you have any questions / comments.
